from yahooquery import Ticker
import yfinance as yf

# aapl = Ticker('T.TO')
# aapl_yf = yf.Ticker('AAPL')
# print(aapl_yf.info)

# for key, val in aapl.summary_detail.items():
#     print(type(val))
#     if type(val) == dict:
#         for k, v in val.items():
#             print(k, v)


def get_historical_fx(source_curr, target_curr, period='4y'):
    symbol = f"{source_curr}{target_curr}=X"
    fa = Ticker(symbol)
    
    # Fetch historical data
    # '1d' interval gives you the daily End of Day (EOD) rate
    df = fa.history(period=period, interval='1d')
    
    # YahooQuery returns a MultiIndex (symbol, date)
    # We reset it to make it a flat table for PostgreSQL
    df = df.reset_index()
    
    # Rename columns to match our Daily_FX_Rates table
    df = df[['date', 'close']].rename(columns={
        'date': 'rate_date',
        'close': 'close_rate'
    })
    
    df['currency_pair'] = symbol
    return df

# Example: Get 5 years of USD to CAD
usd_cad_history = get_historical_fx('USD', 'CAD')
print(usd_cad_history)