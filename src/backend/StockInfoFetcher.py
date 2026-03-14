'''
Adapter pattern for multiple adapters (yfinance and yquery fetches data in different format) 
'''
class InfoFetcher:
    def get_stock_generic_info(self):
        pass

    def get_ex_dividend_date(self):
        pass

    def forcast_next_ytd_dividend_cumulative_sum(self):
        pass

    def get_daily_stock_prices(self):
        pass

    def get_daily_fx_rates(self):
        pass


class yfinanceInfoFetcher(InfoFetcher):
    def get_stock_generic_info(self):
        pass


class yqueryInfoFetcher(InfoFetcher):
    def get_ex_dividend_date(self):
        pass