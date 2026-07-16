import datetime
from decimal import Decimal
from typing import List, Optional
import uuid

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, UniqueConstraint
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
