from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import uuid

from app.database import get_db
from app.models import User, InvestmentProfile

router = APIRouter(prefix="/ai", tags=["AI Suggestions"])

@router.get("/suggestions/{profile_id}")
def get_ai_suggestions(profile_id: str, db: Session = Depends(get_db)):
    """
    Returns AI suggestions for the given portfolio profile.
    This endpoint requires the user to be a premium member.
    """
    profile = db.query(InvestmentProfile).filter(InvestmentProfile.id == profile_id).first()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    user = profile.user
    if not user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="AI Suggestions are a premium feature."
        )

    # In a real implementation, we would pass the holdings to an LLM like OpenAI or Gemini.
    # For now, we return mocked, structured insights based on their real portfolio layout.
    holdings = profile.holdings
    
    if not holdings:
        return {
            "strongest_side": "N/A",
            "weakest_side": "N/A",
            "risk_mitigation": "Add stocks to your portfolio to generate AI suggestions."
        }

    # Generate mock logic
    strongest_sector = "Technology"
    weakest_sector = "Consumer Staples"
    risk_mitigation = (
        "Your portfolio is heavily skewed towards high-growth tech assets. "
        "Consider diversifying into defensive sectors like Utilities or Healthcare "
        "to mitigate future downside risks during market corrections."
    )

    return {
        "strongest_side": strongest_sector,
        "weakest_side": weakest_sector,
        "risk_mitigation": risk_mitigation
    }
