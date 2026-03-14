from StockInfoFetcher import yfinanceInfoFetcher, yqueryInfoFetcher
class BackendServiceProvider:
    '''
    Service provider class that will be used by the orchastrator tool like Airflow, dbt.
    '''
    def __init__(self, name, teller: Teller = None):
        self.name = name
        self.teller = teller
        self.meta_data_provider = yfinanceInfoFetcher()
        self.dividend_data_provider = yqueryInfoFetcher()

    def add_stock_info(self, company_ticker):
        pass

    def create_daily_stock_snapshot(self):
        pass

    def create_daily_fx_rate_snapshot(self):
        pass

    def create_fact_daily_profile_snapshot(self):
        pass

class Teller:

    def __init__(self, serve_client_id, serve_profile):
        self.client_id = serve_client_id
        self.profile = serve_profile

    def add_stocks(self, ticker, amount, transaction_date):
        pass

    def subtract_stocks(self, ticker, amount, transaction_date):
        pass

    def get_dividend_earned(self):
        pass

    def update_profile_holdings(self):
        pass

