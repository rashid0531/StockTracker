import cv2
import numpy as np
import easyocr
import re
from fastapi import APIRouter, UploadFile, File, HTTPException
from typing import List

router = APIRouter(prefix="/import", tags=["import"])

reader = None

def get_reader():
    global reader
    if reader is None:
        reader = easyocr.Reader(['en'])
    return reader

def stitch_images(images: List[np.ndarray]) -> np.ndarray:
    if len(images) == 0:
        return None
    if len(images) == 1:
        return images[0]
    
    stitched = images[0]
    for i in range(1, len(images)):
        img2 = images[i]
        
        if stitched.shape[1] != img2.shape[1]:
            img2 = cv2.resize(img2, (stitched.shape[1], int(img2.shape[0] * stitched.shape[1] / img2.shape[1])))

        h1, w1 = stitched.shape[:2]
        h2, w2 = img2.shape[:2]
        
        template_h = int(h1 * 0.2)
        template = stitched[h1-template_h:h1, :]
        
        search_h = int(h2 * 0.5)
        search_region = img2[0:search_h, :]
        
        try:
            res = cv2.matchTemplate(search_region, template, cv2.TM_CCOEFF_NORMED)
            min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
            
            if max_val > 0.8:
                overlap_start = max_loc[1]
                stitched = np.vstack((stitched, img2[overlap_start + template_h:]))
            else:
                stitched = np.vstack((stitched, img2))
        except Exception:
            stitched = np.vstack((stitched, img2))

    return stitched

@router.post("/ocr")
async def extract_portfolio_ocr(files: List[UploadFile] = File(...)):
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")
    
    images = []
    for file in files:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is not None:
            images.append(img)
            
    if not images:
        raise HTTPException(status_code=400, detail="Invalid images")
        
    stitched_img = stitch_images(images)
    
    r = get_reader()
    results = r.readtext(stitched_img)
    
    holdings = []
    lines = []
    for (bbox, text, prob) in results:
        y_center = sum([p[1] for p in bbox]) / 4
        x_center = sum([p[0] for p in bbox]) / 4
        lines.append({
            'text': text.strip(),
            'y': y_center,
            'x': x_center
        })
        
    lines.sort(key=lambda item: item['y'])
    
    rows = []
    current_row = []
    current_y = None
    
    for item in lines:
        if current_y is None:
            current_y = item['y']
            current_row.append(item)
        elif abs(item['y'] - current_y) < 20: 
            current_row.append(item)
        else: 
            rows.append(current_row)
            current_row = [item]
            current_y = item['y']
            
    if current_row:
        rows.append(current_row)
        
    ticker_pattern = re.compile(r'^[A-Z]{1,5}$')
    number_pattern = re.compile(r'^\d+(\.\d+)?$')
    
    for row in rows:
        row.sort(key=lambda item: item['x'])
        
        ticker = None
        shares = None
        
        for item in row:
            text = item['text'].replace(',', '')
            if not ticker and ticker_pattern.match(text):
                ticker = text
            elif ticker and not shares and number_pattern.match(text):
                shares = float(text)
                
        if ticker and shares:
            holdings.append({
                "ticker": ticker,
                "shares": shares
            })
            
    return {"status": "success", "data": holdings}
