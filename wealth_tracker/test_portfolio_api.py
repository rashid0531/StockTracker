import unittest
from fastapi.testclient import TestClient
from app.main import app

class TestPortfolioApi(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_root_endpoint(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "online")

    def test_portfolio_summary_endpoint(self):
        response = self.client.get("/api/v1/portfolio/summary")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("total_net_worth_cad", data)
        self.assertIn("stocks_valuation_cad", data)
        self.assertIn("real_estate_equity_cad", data)
        self.assertIn("precious_metals_valuation_cad", data)
        self.assertIn("health_wellness_score", data)
        self.assertGreaterEqual(int(data["health_wellness_score"]), 60)

if __name__ == "__main__":
    unittest.main()
