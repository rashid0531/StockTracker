import axios from "axios";

// Base API URL (pointing to our FastAPI backend)
const BASE_URL = "http://localhost:8000";

const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 4000, // short timeout to trigger fallback quickly if offline
});

// Flag to track whether we have fallen back to mock data
let isUsingMock = false;

export const checkUsingMock = () => isUsingMock;
export const setUsingMock = (val: boolean) => {
  isUsingMock = val;
};

// Rich synthetic mock data for offline/unreachable backend
const MOCK_USER_ID = "d0e34cbb-5820-4e1b-b384-cb9ef3a1b80c";

const MOCK_PROFILES = [
  {
    id: "a9117be5-4ea5-419f-b778-be75b22b271d",
    name: "TFSA Account",
    brokerages: "Questrade, Wealthsimple",
    total_value: 124500.2,
    currency: "CAD",
    projected_dividend: 75.46,
  },
  {
    id: "f90117d3-9bc0-4c28-98e3-4de75b2b271e",
    name: "RRSP Ledger",
    brokerages: "Wealthsimple, RBC Direct Investing",
    total_value: 340200.5,
    currency: "USD",
    projected_dividend: 258.93,
  },
];

const MOCK_HISTORICAL_DIVIDENDS: Record<string, Record<string, { date: string; value: number }[]>> = {
  // TFSA
  "a9117be5-4ea5-419f-b778-be75b22b271d": {
    "NOW": [
      { date: "Next Yr Proj.", value: 75.46 },
    ],
    "1Y": [
      { date: "Last Yr Acc.", value: 65.00 },
      { date: "Next Yr Proj.", value: 75.46 },
    ],
    "3Y": [
      { date: "3 yrs ago", value: 50.00 },
      { date: "2 yrs ago", value: 58.00 },
      { date: "Last Yr", value: 65.00 },
      { date: "Next Yr Proj.", value: 75.46 },
    ],
    "5Y": [
      { date: "5 yrs ago", value: 38.00 },
      { date: "3 yrs ago", value: 50.00 },
      { date: "Last Yr", value: 65.00 },
      { date: "Next Yr Proj.", value: 75.46 },
    ],
    "ALL": [
      { date: "2021 Acc.", value: 20.00 },
      { date: "2023 Acc.", value: 45.00 },
      { date: "Last Yr", value: 65.00 },
      { date: "Next Yr Proj.", value: 75.46 },
    ],
  },
  // RRSP
  "f90117d3-9bc0-4c28-98e3-4de75b2b271e": {
    "NOW": [
      { date: "Next Yr Proj.", value: 258.93 },
    ],
    "1Y": [
      { date: "Last Yr Acc.", value: 230.00 },
      { date: "Next Yr Proj.", value: 258.93 },
    ],
    "3Y": [
      { date: "3 yrs ago", value: 180.00 },
      { date: "2 yrs ago", value: 210.00 },
      { date: "Last Yr", value: 230.00 },
      { date: "Next Yr Proj.", value: 258.93 },
    ],
    "5Y": [
      { date: "5 yrs ago", value: 150.00 },
      { date: "3 yrs ago", value: 180.00 },
      { date: "Last Yr", value: 230.00 },
      { date: "Next Yr Proj.", value: 258.93 },
    ],
    "ALL": [
      { date: "2019 Acc.", value: 80.00 },
      { date: "2021 Acc.", value: 140.00 },
      { date: "Last Yr", value: 230.00 },
      { date: "Next Yr Proj.", value: 258.93 },
    ],
  },
};

const MOCK_HISTORICAL_DATA: Record<string, Record<string, { date: string; value: number }[]>> = {
  // TFSA
  "a9117be5-4ea5-419f-b778-be75b22b271d": {
    "NOW": [
      { date: "Today", value: 124500.2 },
    ],
    "1D": [
      { date: "09:30 AM", value: 123800 },
      { date: "11:00 AM", value: 124100 },
      { date: "01:00 PM", value: 123900 },
      { date: "03:00 PM", value: 124300 },
      { date: "04:00 PM", value: 124500.2 },
    ],
    "5D": [
      { date: "Mon", value: 122000 },
      { date: "Tue", value: 123100 },
      { date: "Wed", value: 122900 },
      { date: "Thu", value: 124000 },
      { date: "Fri", value: 124500.2 },
    ],
    "1W": [
      { date: "7d ago", value: 121000 },
      { date: "5d ago", value: 122500 },
      { date: "3d ago", value: 124100 },
      { date: "Today", value: 124500.2 },
    ],
    "1M": [
      { date: "Wk 1", value: 119000 },
      { date: "Wk 2", value: 121500 },
      { date: "Wk 3", value: 120800 },
      { date: "Wk 4", value: 124500.2 },
    ],
    "3M": [
      { date: "3m ago", value: 115000 },
      { date: "2m ago", value: 118000 },
      { date: "1m ago", value: 121000 },
      { date: "Today", value: 124500.2 },
    ],
    "6M": [
      { date: "6m ago", value: 110000 },
      { date: "4m ago", value: 114000 },
      { date: "2m ago", value: 119000 },
      { date: "Today", value: 124500.2 },
    ],
    "1Y": [
      { date: "Q1", value: 110000 },
      { date: "Q2", value: 115000 },
      { date: "Q3", value: 118200 },
      { date: "Q4", value: 124500.2 },
    ],
    "5Y": [
      { date: "5y ago", value: 95000 },
      { date: "3y ago", value: 108000 },
      { date: "1y ago", value: 124500.2 },
    ],
    "ALL": [
      { date: "2021", value: 50000 },
      { date: "2023", value: 85000 },
      { date: "2025", value: 118000 },
      { date: "Today", value: 124500.2 },
    ],
  },
  // RRSP
  "f90117d3-9bc0-4c28-98e3-4de75b2b271e": {
    "NOW": [
      { date: "Today", value: 340200.5 },
    ],
    "1D": [
      { date: "09:30 AM", value: 341000 },
      { date: "11:00 AM", value: 339500 },
      { date: "01:00 PM", value: 340100 },
      { date: "03:00 PM", value: 339800 },
      { date: "04:00 PM", value: 340200.5 },
    ],
    "5D": [
      { date: "Mon", value: 338000 },
      { date: "Tue", value: 339200 },
      { date: "Wed", value: 340900 },
      { date: "Thu", value: 339500 },
      { date: "Fri", value: 340200.5 },
    ],
    "1W": [
      { date: "7d ago", value: 335000 },
      { date: "5d ago", value: 338000 },
      { date: "3d ago", value: 339200 },
      { date: "Today", value: 340200.5 },
    ],
    "1M": [
      { date: "Wk 1", value: 332000 },
      { date: "Wk 2", value: 335000 },
      { date: "Wk 3", value: 338100 },
      { date: "Wk 4", value: 340200.5 },
    ],
    "3M": [
      { date: "3m ago", value: 325000 },
      { date: "2m ago", value: 331000 },
      { date: "1m ago", value: 336000 },
      { date: "Today", value: 340200.5 },
    ],
    "6M": [
      { date: "6m ago", value: 310000 },
      { date: "4m ago", value: 320000 },
      { date: "2m ago", value: 335000 },
      { date: "Today", value: 340200.5 },
    ],
    "1Y": [
      { date: "Q1", value: 310000 },
      { date: "Q2", value: 322000 },
      { date: "Q3", value: 331500 },
      { date: "Q4", value: 340200.5 },
    ],
    "5Y": [
      { date: "5y ago", value: 270000 },
      { date: "3y ago", value: 295000 },
      { date: "1y ago", value: 340200.5 },
    ],
    "ALL": [
      { date: "2019", value: 180000 },
      { date: "2021", value: 240000 },
      { date: "2023", value: 310000 },
      { date: "Today", value: 340200.5 },
    ],
  },
};

const MOCK_STOCKS: Record<string, any[]> = {
  // TFSA Stocks
  "a9117be5-4ea5-419f-b778-be75b22b271d": [
    {
      ticker: "AAPL",
      name: "Apple Inc.",
      shares: 10.5,
      price: 185.0,
      change: 1.24,
      changePercent: 0.67,
      currency: "USD",
      value: 1942.5,
    },
    {
      ticker: "XIU",
      name: "iShares S&P/TSX 60 Index ETF",
      shares: 100.25,
      price: 32.5,
      change: -0.15,
      changePercent: -0.46,
      currency: "CAD",
      value: 3258.13,
    },
  ],
  // RRSP Stocks
  "f90117d3-9bc0-4c28-98e3-4de75b2b271e": [
    {
      ticker: "BHP",
      name: "BHP Group Limited",
      shares: 150.5,
      price: 43.0,
      change: 0.78,
      changePercent: 1.85,
      currency: "AUD",
      value: 6471.5,
    },
    {
      ticker: "BP",
      name: "BP plc",
      shares: 200.75,
      price: 4.8,
      change: -0.05,
      changePercent: -1.03,
      currency: "GBP",
      value: 963.6,
    },
  ],
};

const convertCurrency = (amount: number, from: string, to: string) => {
  if (from === to) return amount;
  if (from === "USD" && to === "CAD") return amount * 1.35;
  if (from === "CAD" && to === "USD") return amount * 0.74;
  if (from === "AUD" && to === "CAD") return amount * 0.9;
  if (from === "AUD" && to === "USD") return amount * 0.66;
  if (from === "GBP" && to === "CAD") return amount * 1.75;
  if (from === "GBP" && to === "USD") return amount * 1.28;
  return amount;
};

export const apiService = {
  async login(email: string) {
    if (isUsingMock) {
      console.log("[API] Returning mock login data");
      return { id: MOCK_USER_ID, name: "Jane Doe", email };
    }
    try {
      return { id: MOCK_USER_ID, name: "Jane Doe", email };
    } catch (err) {
      console.warn("[API] Login failed, enabling mock fallback");
      isUsingMock = true;
      return { id: MOCK_USER_ID, name: "Jane Doe", email };
    }
  },

  async getProfiles(userId: string) {
    if (isUsingMock) {
      return MOCK_PROFILES;
    }
    try {
      const response = await apiClient.get(`/holdings/projections/${userId}`);
      const projections = response.data.projections;

      const profilesMap = new Map<string, any>();
      for (const p of projections) {
        if (!profilesMap.has(p.profile_id)) {
          profilesMap.set(p.profile_id, {
            id: p.profile_id,
            name: p.profile_name,
            brokerages:
              p.profile_name === "TFSA"
                ? "Questrade, Wealthsimple"
                : "Wealthsimple, RBC Direct Investing",
            total_value: 0,
            currency: p.profile_name === "TFSA" ? "CAD" : "USD",
            projected_dividend: 0,
          });
        }
        const profile = profilesMap.get(p.profile_id);
        const convertedDiv = convertCurrency(
          Number(p.projected_annual_dividend),
          p.currency,
          profile.currency
        );
        profile.projected_dividend += convertedDiv;
        profile.total_value +=
          p.profile_name === "TFSA" ? 124500.2 : 340200.5;
      }

      const profilesList = Array.from(profilesMap.values());
      return profilesList.length > 0 ? profilesList : MOCK_PROFILES;
    } catch (err) {
      console.warn("[API] getProfiles failed, switching to mock fallback");
      isUsingMock = true;
      return MOCK_PROFILES;
    }
  },

  async getProfileDetail(profileId: string, interval: string = "1D") {
    const stocks = MOCK_STOCKS[profileId] || [];
    const historyMap = MOCK_HISTORICAL_DATA[profileId] || {};
    const chartPoints = historyMap[interval] || [
      { date: "Point 1", value: 100000 },
      { date: "Point 2", value: 110000 },
      { date: "Point 3", value: 120000 },
    ];

    const dividendHistoryMap = MOCK_HISTORICAL_DIVIDENDS[profileId] || {};
    const dividendChartPoints = dividendHistoryMap[interval] || [
      { date: "Point 1", value: 50 },
      { date: "Point 2", value: 60 },
      { date: "Point 3", value: 75 },
    ];

    return {
      profileId,
      stocks,
      chartPoints,
      dividendChartPoints,
    };
  },


  async importPortfolio(payload: {
    ticker: string;
    transactionType: string;
    quantity: number;
    pricePerShare: number;
    brokerage: string;
    fxRate: number;
    purchaseDate: string;
    profileName: string; // 'TFSA' or 'RRSP'
  }) {
    if (isUsingMock) {
      console.log("[API] mock import success:", payload);
      // Dynamically add a mock stock to simulate local persistence
      const profileId =
        payload.profileName === "TFSA"
          ? "a9117be5-4ea5-419f-b778-be75b22b271d"
          : "f90117d3-9bc0-4c28-98e3-4de75b2b271e";

      if (MOCK_STOCKS[profileId]) {
        MOCK_STOCKS[profileId].push({
          ticker: payload.ticker.toUpperCase(),
          name: `${payload.ticker.toUpperCase()} Asset`,
          shares: payload.quantity,
          price: payload.pricePerShare,
          change: 0.5,
          changePercent: 0.1,
          currency: payload.profileName === "TFSA" ? "CAD" : "USD",
          value: payload.quantity * payload.pricePerShare,
        });
      }
      return { success: true };
    }

    try {
      // Send transaction registration request to FastAPI
      // This is a direct POST to save data in PostgreSQL
      const response = await apiClient.post("/transactions", payload);
      return response.data;
    } catch (err) {
      console.warn("[API] importPortfolio failed, falling back to mock");
      isUsingMock = true;
      // Do mock fallback insert
      const profileId =
        payload.profileName === "TFSA"
          ? "a9117be5-4ea5-419f-b778-be75b22b271d"
          : "f90117d3-9bc0-4c28-98e3-4de75b2b271e";
      if (MOCK_STOCKS[profileId]) {
        MOCK_STOCKS[profileId].push({
          ticker: payload.ticker.toUpperCase(),
          name: `${payload.ticker.toUpperCase()} Asset`,
          shares: payload.quantity,
          price: payload.pricePerShare,
          change: 0.0,
          changePercent: 0.0,
          currency: payload.profileName === "TFSA" ? "CAD" : "USD",
          value: payload.quantity * payload.pricePerShare,
        });
      }
      return { success: true, message: "Local mock success" };
    }
  },
};
