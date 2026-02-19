### Core Layer
User: [userID (PK), first_name, last_name, city, state, country]

Stock: [stockID (PK), ticker, stock_full_name, stock_exchange, currency]

Profile: [profileID (PK), ownerID (FK), profile_name, profile_type]


### Transaction Layer
stock_transactions: [transactionID (PK), profileID (FK), stockID (FK), transaction_type, quantity, price_per_stock_in_stock_currency, fx_rate, fees, total_price_profile_currency, date_of_event]

### History Layer
stock_daily_snapshot: [stockID (FK), stock_capture_date, end_of_day_price_stock_currency]

fx_rate_daily_snapshot: [fxID (PK), currency_pair, fx_rate_date, closing_rate]

profile_daily_snapshot: [profileID (FK), profile_capture_date, total_market_value_profile_currency]

dividend_monthly_snapshot: [stockID (FK), dividend_yield, dividend_rate_stock_currency, payout_frequency, next_ex_date, last_updated]