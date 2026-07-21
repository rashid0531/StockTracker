-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. Investment Profiles Table
CREATE TABLE IF NOT EXISTS investment_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL, -- e.g., 'TFSA', 'RRSP'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 3. Brokerage Accounts Table
CREATE TABLE IF NOT EXISTS brokerage_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES investment_profiles(id) ON DELETE CASCADE NOT NULL,
    broker_name VARCHAR(255) NOT NULL, -- e.g., 'Questrade', 'Wealthsimple', 'RBC Direct Investing'
    account_number VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 4. Stock Registry Table
CREATE TABLE IF NOT EXISTS stock_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticker VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'AAPL', 'VCN.TO'
    name VARCHAR(255) NOT NULL,
    exchange VARCHAR(50) NOT NULL, -- e.g., 'TSX', 'NASDAQ', 'NYSE', 'ASX', 'LSE'
    country VARCHAR(50) NOT NULL, -- e.g., 'Canada', 'USA', 'Australia', 'UK'
    currency VARCHAR(3) NOT NULL, -- e.g., 'CAD', 'USD', 'AUD', 'GBP'
    current_price NUMERIC(14, 4) DEFAULT 0.0000 NOT NULL,
    annualized_dividend_per_share NUMERIC(14, 4) DEFAULT 0.0000 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 5. Daily Stock Prices Time-Series Table
CREATE TABLE IF NOT EXISTS daily_stock_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id UUID REFERENCES stock_registry(id) ON DELETE CASCADE NOT NULL,
    trading_date DATE NOT NULL,
    adj_close_price NUMERIC(14, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_stock_date UNIQUE (stock_id, trading_date)
);

-- Create a composite index on (stock_id, trading_date DESC) to optimize performance
CREATE INDEX IF NOT EXISTS idx_stock_prices_composite ON daily_stock_prices (stock_id, trading_date DESC);

-- 6. Stock Transactions Hot Ledger Table (Immutable)
CREATE TABLE IF NOT EXISTS stock_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID REFERENCES brokerage_accounts(id) ON DELETE CASCADE NOT NULL,
    stock_id UUID REFERENCES stock_registry(id) ON DELETE CASCADE NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    transaction_type VARCHAR(10) NOT NULL, -- 'BUY', 'SELL'
    quantity NUMERIC(14, 4) NOT NULL, -- supports fractional shares
    price_per_share NUMERIC(14, 4) NOT NULL,
    currency VARCHAR(3) NOT NULL, -- e.g., 'CAD', 'USD'
    fx_rate NUMERIC(14, 4) DEFAULT 1.0000 NOT NULL, -- Exchange rate to native currency
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 7. FX Historical Rates Table
CREATE TABLE IF NOT EXISTS fx_historical_rates (
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(14, 4) NOT NULL,
    rate_date DATE NOT NULL,
    PRIMARY KEY (from_currency, to_currency, rate_date)
);

-- 8. Compressed Historical Balances Rollup Table (Cold storage for positions > 5 years old)
CREATE TABLE IF NOT EXISTS compressed_historical_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID REFERENCES brokerage_accounts(id) ON DELETE CASCADE NOT NULL,
    stock_id UUID REFERENCES stock_registry(id) ON DELETE CASCADE NOT NULL,
    balance_date DATE NOT NULL,
    quantity NUMERIC(14, 4) NOT NULL,
    compressed_fx_rate NUMERIC(14, 4) NOT NULL, -- Volume-Weighted Exchange Rate
    currency VARCHAR(3) NOT NULL, -- Native currency of the stock
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_compressed_balance UNIQUE (account_id, stock_id, balance_date)
);

-- 9. Dividend Schedule Table
CREATE TABLE IF NOT EXISTS dividend_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id UUID REFERENCES stock_registry(id) ON DELETE CASCADE NOT NULL,
    ex_dividend_date DATE,
    payment_date DATE,
    amount_per_share NUMERIC(14, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 10. User Stock Theses Table
CREATE TABLE IF NOT EXISTS user_stock_theses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    stock_id UUID REFERENCES stock_registry(id) ON DELETE CASCADE NOT NULL,
    thesis_text TEXT NOT NULL,
    review_interval_days INT DEFAULT 180 NOT NULL,
    last_reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_user_stock_thesis UNIQUE (user_id, stock_id)
);

-- 11. Database View: view_all_time_share_positions
CREATE OR REPLACE VIEW view_all_time_share_positions AS
SELECT
    account_id,
    stock_id,
    transaction_date::date AS position_date,
    CASE 
        WHEN transaction_type = 'BUY' THEN quantity 
        WHEN transaction_type = 'SELL' THEN -quantity 
        ELSE 0.0000 
    END AS share_change,
    fx_rate,
    'HOT' AS storage_type
FROM stock_transactions
UNION ALL
SELECT
    account_id,
    stock_id,
    balance_date AS position_date,
    quantity AS share_change,
    compressed_fx_rate AS fx_rate,
    'COLD' AS storage_type
FROM compressed_historical_balances;

-- 10. Database View: view_user_stock_holdings (Live Share Counts per user, profile, account, stock)
CREATE OR REPLACE VIEW view_user_stock_holdings AS
SELECT
    u.id AS user_id,
    p.id AS profile_id,
    p.name AS profile_name,
    a.id AS account_id,
    a.broker_name,
    s.id AS stock_id,
    s.ticker,
    s.exchange,
    s.currency AS native_currency,
    s.annualized_dividend_per_share,
    COALESCE(SUM(vp.share_change), 0.0000) AS total_shares
FROM view_all_time_share_positions vp
JOIN brokerage_accounts a ON vp.account_id = a.id
JOIN investment_profiles p ON a.profile_id = p.id
JOIN users u ON p.user_id = u.id
JOIN stock_registry s ON vp.stock_id = s.id
GROUP BY u.id, p.id, p.name, a.id, a.broker_name, s.id, s.ticker, s.exchange, s.currency, s.annualized_dividend_per_share;
