from decimal import Decimal
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, Field


class UserBase(BaseModel):
    email: str
    name: str


class UserCreate(UserBase):
    pass


class UserResponse(UserBase):
    id: UUID

    class Config:
        from_attributes = True


class ProfileBase(BaseModel):
    name: str  # e.g., 'TFSA', 'RRSP'


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
