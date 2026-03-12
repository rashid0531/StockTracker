## Core Layer
user: [user_id (PK), first_name, last_name, email_address, city, state, country]

stock_info: [stock_id (PK), ticker, stock_full_name, stock_exchange, currency, industry, sector]

profile: [profileID (PK), ownerID (FK), profile_name, profile_currency]

## Transactional and State Management Layer
stock_transactions: [transactionID (PK), profileID (FK), stock_id (FK), transaction_type, quantity, date_of_event]

<!-- Accumulated and overwritten in each transaction occured on the profile-->
profile_current_holdings: [profileID (FK), stock_id (FK), quantity, last_updated] 

stock_daily_snapshot: [stock_id (FK), stock_capture_date, end_of_day_price_stock_currency, exDividendDate, dividendYield, dividendRate]

fx_rate_daily_snapshot: [fxID (PK), currency_pair, fx_rate_date, closing_rate]

dividend_monthly_snapshot: [stock_id (FK), dividend_yield, dividend_rate_stock_currency, payout_frequency, next_ex_date, last_updated]

## Analytics Layer

<!-- Aggregated daily after market close from tables 'profile_current_holdings' and 'fx_rate_daily_snapshot'-->
fact_daily_profile_snapshot: [fdps_id (auto increment), snapshot_date, profile_id, stock_id, quantity, fx_rate, sub_total_profile_currency, dividend_accured_profile_currency]




