## Core Layer
user: [user_id (PK), first_name, last_name, city, state, country]

stock: [stock_id (PK), ticker, stock_full_name, stock_exchange, currency]

profile: [profileID (PK), ownerID (FK), profile_name, profile_type]

## Transactional and State Management Layer
stock_transactions: [transactionID (PK), profileID (FK), stock_id (FK), transaction_type, quantity, price_per_stock_in_stock_currency, fx_rate, fees, total_price_profile_currency, date_of_event]

profile_current_position: [profileID (FK), stock_id (FK), quantity, last_updated]

stock_daily_snapshot: [stock_id (FK), stock_capture_date, end_of_day_price_stock_currency]

fx_rate_daily_snapshot: [fxID (PK), currency_pair, fx_rate_date, closing_rate]

dividend_monthly_snapshot: [stock_id (FK), dividend_yield, dividend_rate_stock_currency, payout_frequency, next_ex_date, last_updated]

## Analytics Layer

fact_daily_profile_snapshot: [fdps_id (auto increment), snapshot_date, profile_id, stock_id, quantity, price_per_stock_in_stock_currency, fx_rate, fees, total_price_profile_currency,
dividend_accured_profile_currency]




