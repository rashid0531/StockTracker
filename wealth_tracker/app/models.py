import datetime
from decimal import Decimal
from typing import List, Optional
import uuid

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, UniqueConstraint, Text, JSON, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    primary_country: Mapped[str] = mapped_column(String(50), default="Canada", nullable=False)
    primary_currency: Mapped[str] = mapped_column(String(3), default="CAD", nullable=False)
    active_modules: Mapped[list[str]] = mapped_column(JSON, default=lambda: ["STOCKS"], nullable=False)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    profiles: Mapped[List["InvestmentProfile"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class InvestmentProfile(Base):
    __tablename__ = "investment_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    country: Mapped[str] = mapped_column(String(50), default="Canada", nullable=False)
    account_type: Mapped[str] = mapped_column(String(100), default="TFSA", nullable=False)
    pillar_category: Mapped[str] = mapped_column(String(50), default="Stocks", nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="profiles")
    accounts: Mapped[List["BrokerageAccount"]] = relationship(
        back_populates="profile", cascade="all, delete-orphan"
    )


class BrokerageAccount(Base):
    __tablename__ = "brokerage_accounts"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("investment_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    broker_name: Mapped[str] = mapped_column(
        String(255), nullable=False
    )  # e.g. Questrade, Wealthsimple
    account_number: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    profile: Mapped["InvestmentProfile"] = relationship(back_populates="accounts")
    transactions: Mapped[List["StockTransaction"]] = relationship(
        back_populates="account", cascade="all, delete-orphan"
    )
    compressed_balances: Mapped[List["CompressedHistoricalBalance"]] = (
        relationship(back_populates="account", cascade="all, delete-orphan")
    )


class StockRegistry(Base):
    __tablename__ = "stock_registry"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    ticker: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    exchange: Mapped[str] = mapped_column(
        String(50), nullable=False
    )  # e.g., TSX, NASDAQ
    country: Mapped[str] = mapped_column(
        String(50), nullable=False
    )  # e.g. Canada, USA
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False
    )  # e.g. CAD, USD
    current_price: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), default=Decimal("0.0000")
    )
    annualized_dividend_per_share: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), default=Decimal("0.0000")
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    prices: Mapped[List["DailyStockPrice"]] = relationship(
        back_populates="stock", cascade="all, delete-orphan"
    )
    transactions: Mapped[List["StockTransaction"]] = relationship(
        back_populates="stock", cascade="all, delete-orphan"
    )
    compressed_balances: Mapped[List["CompressedHistoricalBalance"]] = (
        relationship(back_populates="stock", cascade="all, delete-orphan")
    )


class DailyStockPrice(Base):
    __tablename__ = "daily_stock_prices"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stock_registry.id", ondelete="CASCADE"),
        nullable=False,
    )
    trading_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    adj_close_price: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), nullable=False
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    stock: Mapped["StockRegistry"] = relationship(back_populates="prices")

    __table_args__ = (
        UniqueConstraint("stock_id", "trading_date", name="uq_stock_date"),
    )


class StockTransaction(Base):
    __tablename__ = "stock_transactions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    account_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("brokerage_accounts.id", ondelete="CASCADE"),
        nullable=False,
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stock_registry.id", ondelete="CASCADE"),
        nullable=False,
    )
    transaction_date: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    transaction_type: Mapped[str] = mapped_column(
        String(10), nullable=False
    )  # BUY or SELL
    quantity: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    price_per_share: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), nullable=False
    )
    currency: Mapped[str] = mapped_column(String(3), nullable=False)
    fx_rate: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), default=Decimal("1.0000")
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    account: Mapped["BrokerageAccount"] = relationship(
        back_populates="transactions"
    )
    stock: Mapped["StockRegistry"] = relationship(back_populates="transactions")


class FXHistoricalRate(Base):
    __tablename__ = "fx_historical_rates"

    from_currency: Mapped[str] = mapped_column(String(3), primary_key=True)
    to_currency: Mapped[str] = mapped_column(String(3), primary_key=True)
    exchange_rate: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), nullable=False
    )
    rate_date: Mapped[datetime.date] = mapped_column(Date, primary_key=True)


class CompressedHistoricalBalance(Base):
    __tablename__ = "compressed_historical_balances"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    account_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("brokerage_accounts.id", ondelete="CASCADE"),
        nullable=False,
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stock_registry.id", ondelete="CASCADE"),
        nullable=False,
    )
    balance_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    compressed_fx_rate: Mapped[Decimal] = mapped_column(
        Numeric(14, 4), nullable=False
    )
    currency: Mapped[str] = mapped_column(String(3), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    account: Mapped["BrokerageAccount"] = relationship(
        back_populates="compressed_balances"
    )
    stock: Mapped["StockRegistry"] = relationship(
        back_populates="compressed_balances"
    )

    __table_args__ = (
        UniqueConstraint(
            "account_id", "stock_id", "balance_date", name="uq_compressed_balance"
        ),
    )


class DividendSchedule(Base):
    __tablename__ = "dividend_schedule"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stock_registry.id", ondelete="CASCADE"),
        nullable=False,
    )
    ex_dividend_date: Mapped[Optional[datetime.date]] = mapped_column(Date, nullable=True)
    payment_date: Mapped[Optional[datetime.date]] = mapped_column(Date, nullable=True)
    amount_per_share: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    stock: Mapped["StockRegistry"] = relationship()


class DividendReceived(Base):
    """Log of actual dividend payments received by the user."""
    __tablename__ = "dividend_received"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stock_registry.id", ondelete="CASCADE"),
        nullable=False,
    )
    account_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("brokerage_accounts.id", ondelete="SET NULL"),
        nullable=True,
    )
    payment_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    amount_per_share: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    shares_at_payment: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    total_received: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship()
    stock: Mapped["StockRegistry"] = relationship()


class UserStockThesis(Base):
    __tablename__ = "user_stock_theses"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stock_registry.id", ondelete="CASCADE"),
        nullable=False,
    )
    thesis_text: Mapped[str] = mapped_column(Text, nullable=False)
    review_interval_days: Mapped[int] = mapped_column(default=180, nullable=False)
    last_reviewed_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship()
    stock: Mapped["StockRegistry"] = relationship()

    __table_args__ = (
        UniqueConstraint("user_id", "stock_id", name="uq_user_stock_thesis"),
    )


# Read-Only Database View mappings
class ViewAllTimeSharePosition(Base):
    __tablename__ = "view_all_time_share_positions"

    account_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True
    )
    stock_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    position_date: Mapped[datetime.date] = mapped_column(Date, primary_key=True)
    share_change: Mapped[Decimal] = mapped_column(Numeric(14, 4))
    fx_rate: Mapped[Decimal] = mapped_column(Numeric(14, 4))
    storage_type: Mapped[str] = mapped_column(String)


class ViewUserStockHolding(Base):
    __tablename__ = "view_user_stock_holdings"

    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True
    )
    profile_name: Mapped[str] = mapped_column(String(255))
    profile_country: Mapped[str] = mapped_column(String(50))
    account_type: Mapped[str] = mapped_column(String(100))
    account_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True
    )
    broker_name: Mapped[str] = mapped_column(String(255))
    stock_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    ticker: Mapped[str] = mapped_column(String(50))
    exchange: Mapped[str] = mapped_column(String(50))
    native_currency: Mapped[str] = mapped_column(String(3))
    annualized_dividend_per_share: Mapped[Decimal] = mapped_column(Numeric(14, 4))
    total_shares: Mapped[Decimal] = mapped_column(Numeric(14, 4))


class RealEstateAsset(Base):
    __tablename__ = "real_estate_assets"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    property_name: Mapped[str] = mapped_column(String(255), nullable=False)
    property_type: Mapped[str] = mapped_column(String(100), nullable=False)  # Structural type or label
    region: Mapped[str] = mapped_column(String(50), default="North America (NA)", nullable=False)
    property_category: Mapped[str] = mapped_column(String(100), default="Single-Family", nullable=False)
    structural_type: Mapped[str] = mapped_column(String(100), default="Single-Family Detached", nullable=False)
    tenure_model: Mapped[str] = mapped_column(String(100), default="Freehold", nullable=False)
    purchase_price: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    current_value: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    mortgage_balance: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0.0)
    monthly_rent_income: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0.0)
    monthly_expenses: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0.0)
    address: Mapped[str] = mapped_column(String(500), nullable=True)
    purchase_date: Mapped[datetime.date] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class PreciousMetalAsset(Base):
    __tablename__ = "precious_metal_assets"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    metal_type: Mapped[str] = mapped_column(String(50), nullable=False)  # Gold, Silver, Platinum, Palladium, Bronze
    form: Mapped[str] = mapped_column(String(100), nullable=False)  # Bullion Bar, Coin, Jewelry, Grain
    weight_oz: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    purity_percent: Mapped[Decimal] = mapped_column(Numeric(6, 3), default=99.9)
    purchase_price_per_oz: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    current_spot_price_per_oz: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    storage_location: Mapped[str] = mapped_column(String(255), default="Home Safe")
    purchase_date: Mapped[datetime.date] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class HealthMetricLog(Base):
    __tablename__ = "health_metric_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    metric_type: Mapped[str] = mapped_column(String(100), nullable=False)  # Weight, Body Fat %, Resting HR, Sleep Score, Activity
    value: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    unit: Mapped[str] = mapped_column(String(50), nullable=False)  # kg, lbs, bpm, %, hours, score
    notes: Mapped[str] = mapped_column(String(500), nullable=True)
    logged_at: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

