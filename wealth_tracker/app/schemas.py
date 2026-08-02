from datetime import date, datetime
from decimal import Decimal
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, Field


class UserBase(BaseModel):
    email: str
    name: str
    primary_country: Optional[str] = "Canada"
    primary_currency: Optional[str] = "CAD"


class UserCreate(UserBase):
    pass


class UserResponse(UserBase):
    id: UUID

    class Config:
        from_attributes = True


class ProfileBase(BaseModel):
    name: str  # e.g., 'TFSA Growth', 'Primary Residence'
    country: str = "Canada"  # Jurisdiction country
    account_type: str = "TFSA"  # Account type
    pillar_category: str = "Stocks"  # Stocks, Real-Estate, Precious Metals, Health


class ProfileCreate(ProfileBase):
    user_id: UUID


class ProfileResponse(ProfileBase):
    id: UUID
    user_id: UUID

    class Config:
        from_attributes = True


class BrokerageAccountBase(BaseModel):
    broker_name: str
    account_number: Optional[str] = None


class BrokerageAccountCreate(BrokerageAccountBase):
    profile_id: UUID


class BrokerageAccountResponse(BrokerageAccountBase):
    id: UUID
    profile_id: UUID

    class Config:
        from_attributes = True


class StockRegistryBase(BaseModel):
    ticker: str
    name: str
    exchange: str
    country: str
    currency: str
    current_price: Decimal
    annualized_dividend_per_share: Decimal


class StockRegistryResponse(StockRegistryBase):
    id: UUID

    class Config:
        from_attributes = True


class StockTransactionBase(BaseModel):
    account_id: UUID
    stock_id: UUID
    transaction_date: str
    transaction_type: str  # BUY or SELL
    quantity: Decimal
    price_per_share: Decimal
    currency: str
    fx_rate: Decimal = Field(default=Decimal("1.0000"))


# Project output structures
class DividendProjection(BaseModel):
    profile_id: UUID
    profile_name: str
    currency: str
    projected_annual_dividend: Decimal

    class Config:
        from_attributes = True


class UserDividendProjectionsResponse(BaseModel):
    user_id: UUID
    projections: List[DividendProjection]


class ProfileValue(BaseModel):
    profile_id: UUID
    profile_name: str
    country: str = "Canada"
    account_type: str = "TFSA"
    total_value: Decimal

    class Config:
        from_attributes = True


class UserProfileValuesResponse(BaseModel):
    user_id: UUID
    target_currency: str
    profiles: List[ProfileValue]


# Phase 1 Features schemas
class DividendCalendarItem(BaseModel):
    ticker: str
    stock_name: str
    ex_dividend_date: Optional[date] = None
    payment_date: Optional[date] = None
    amount_per_share: Decimal
    shares_owned: Decimal
    projected_payout: Decimal
    currency: str

    class Config:
        from_attributes = True


class UserDividendCalendarResponse(BaseModel):
    user_id: UUID
    events: List[DividendCalendarItem]


class ThesisCreateUpdate(BaseModel):
    user_id: UUID
    stock_id: UUID
    thesis_text: str
    review_interval_days: Optional[int] = 180


class ThesisResponse(BaseModel):
    stock_id: UUID
    thesis_text: str
    review_interval_days: int
    last_reviewed_at: datetime
    updated_at: datetime
    needs_review: bool

    class Config:
        from_attributes = True


class TransactionCreateRequest(BaseModel):
    profile_id: UUID
    ticker: str
    transaction_type: str  # BUY or SELL
    quantity: Decimal
    price_per_share: Decimal
    currency: str = "USD"
    transaction_date: Optional[str] = None


class TransactionItemResponse(BaseModel):
    id: UUID
    profile_id: UUID
    profile_name: str
    ticker: str
    stock_name: str
    transaction_type: str
    quantity: Decimal
    price_per_share: Decimal
    total_amount: Decimal
    currency: str
    transaction_date: str

    class Config:
        from_attributes = True


class UserTransactionsResponse(BaseModel):
    user_id: UUID
    transactions: List[TransactionItemResponse]


# --- Real Estate Schemas ---
class RealEstateCreateRequest(BaseModel):
    user_id: UUID
    property_name: str
    property_type: str
    purchase_price: Decimal
    current_value: Decimal
    mortgage_balance: Decimal = Decimal("0.0")
    monthly_rent_income: Decimal = Decimal("0.0")
    monthly_expenses: Decimal = Decimal("0.0")
    address: Optional[str] = None
    purchase_date: Optional[date] = None


class RealEstateResponse(BaseModel):
    id: UUID
    user_id: UUID
    property_name: str
    property_type: str
    purchase_price: Decimal
    current_value: Decimal
    mortgage_balance: Decimal
    monthly_rent_income: Decimal
    monthly_expenses: Decimal
    address: Optional[str] = None
    purchase_date: Optional[date] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UserRealEstateResponse(BaseModel):
    user_id: UUID
    total_value: Decimal
    total_mortgage: Decimal
    total_net_equity: Decimal
    total_monthly_cashflow: Decimal
    properties: List[RealEstateResponse]


# --- Precious Metals Schemas ---
class PreciousMetalCreateRequest(BaseModel):
    user_id: UUID
    metal_type: str
    form: str
    weight_oz: Decimal
    purity_percent: Decimal = Decimal("99.9")
    purchase_price_per_oz: Decimal
    current_spot_price_per_oz: Decimal
    storage_location: Optional[str] = "Home Safe"
    purchase_date: Optional[date] = None


class PreciousMetalResponse(BaseModel):
    id: UUID
    user_id: UUID
    metal_type: str
    form: str
    weight_oz: Decimal
    purity_percent: Decimal
    purchase_price_per_oz: Decimal
    current_spot_price_per_oz: Decimal
    storage_location: str
    purchase_date: Optional[date] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UserPreciousMetalsResponse(BaseModel):
    user_id: UUID
    total_value: Decimal
    total_weight_oz: Decimal
    total_gain_loss: Decimal
    metals: List[PreciousMetalResponse]


# --- Health Metrics Schemas ---
class HealthMetricCreateRequest(BaseModel):
    user_id: UUID
    metric_type: str
    value: Decimal
    unit: str
    notes: Optional[str] = None
    logged_at: Optional[date] = None


class HealthMetricResponse(BaseModel):
    id: UUID
    user_id: UUID
    metric_type: str
    value: Decimal
    unit: str
    notes: Optional[str] = None
    logged_at: date
    created_at: datetime

    class Config:
        from_attributes = True


class UserHealthMetricsResponse(BaseModel):
    user_id: UUID
    metrics: List[HealthMetricResponse]


class PortfolioSummaryResponse(BaseModel):
    total_net_worth_cad: Decimal
    stocks_valuation_cad: Decimal
    real_estate_equity_cad: Decimal
    precious_metals_valuation_cad: Decimal
    health_wellness_score: int
    last_updated: str

    class Config:
        from_attributes = True





