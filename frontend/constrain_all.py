import os
import glob

def balance_brackets(text, start_idx):
    stack = []
    for i in range(start_idx, len(text)):
        if text[i] in ['(', '{', '[']:
            stack.append(text[i])
        elif text[i] in [')', '}', ']']:
            if not stack:
                return i
            stack.pop()
            if not stack:
                return i
    return -1

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Skip files that already have the constrained body pattern heavily used
    # Or actually, we only replace if we haven't already.
    
    # We will look for "return Scaffold("
    if "return Scaffold(" not in content:
        return

    # To be safe, we will just wrap the *entire* Scaffold body if it's not already wrapped!
    idx = 0
    modified = False
    
    while True:
        body_idx = content.find("body: ", idx)
        if body_idx == -1:
            break
            
        # check if it's already constrained
        after_body = content[body_idx + 6:].strip()
        if after_body.startswith("Center(") and "ConstrainedBox" in after_body[:50]:
            idx = body_idx + 6
            continue
            
        # Find the start of the expression
        expr_start = body_idx + 6
        
        # We need to read until the next comma that is at the same bracket level, or the end of the Scaffold.
        # This is slightly tricky.
        
        # Instead, let's just do it for files we know need it.
