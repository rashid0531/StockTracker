import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/profile.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  bool _isUsingMock = true; // Default to true since backend is local and may be offline

  bool get isUsingMock => _isUsingMock;
  void setUsingMock(bool val) => _isUsingMock = val;

  static const String mockUserId = "d0e34cbb-5820-4e1b-b384-cb9ef3a1b80c";

  // Mock dividend calendar events
  final List<Map<String, dynamic>> _mockDividendCalendar = [
    {
      "ticker": "AAPL",
      "stock_name": "Apple Inc.",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-08-14",
      "amount_per_share": 0.24,
      "shares_owned": 10.5,
      "projected_payout": 2.52,
      "currency": "USD",
    },
    {
      "ticker": "XIU",
      "stock_name": "iShares S&P/TSX 60 Index ETF",
      "ex_dividend_date": "2026-07-30",
      "payment_date": "2026-08-07",
      "amount_per_share": 0.25,
      "shares_owned": 100.25,
      "projected_payout": 25.0625,
      "currency": "CAD",
    },
    {
      "ticker": "BHP",
      "stock_name": "BHP Group Limited",
      "ex_dividend_date": "2026-08-10",
      "payment_date": "2026-09-02",
      "amount_per_share": 1.20,
      "shares_owned": 150.5,
      "projected_payout": 180.60,
      "currency": "AUD",
    },
    {
      "ticker": "BP",
      "stock_name": "BP plc",
      "ex_dividend_date": "2026-08-15",
      "payment_date": "2026-09-20",
      "amount_per_share": 0.07,
      "shares_owned": 200.75,
      "projected_payout": 14.0525,
      "currency": "GBP",
    }
  ];

  // Mock stock theses
  final Map<String, Map<String, dynamic>> _mockTheses = {
    "a7be54ea-5419-fb77-8be7-5b22b271db11": {
      "stock_id": "a7be54ea-5419-fb77-8be7-5b22b271db11",
      "thesis_text": "Apple has a dominant ecosystem, strong services growth, and robust buyback program. High free cash flow generation makes its dividend extremely secure and likely to grow at 5-10% annually.",
      "review_interval_days": 180,
      "last_reviewed_at": "2026-01-15T12:00:00Z",
      "updated_at": "2026-01-15T12:00:00Z",
      "needs_review": true,
    }
  };

  // Mock profile definitions
  final List<Map<String, dynamic>> _mockProfiles = [
    {
      "id": "a9117be5-4ea5-419f-b778-be75b22b271d",
      "name": "TFSA Account",
      "type": "TFSA",
      "totalValue": 124500.2,
      "totalChange": 4500.2,
      "totalChangePercent": 3.75,
      "annualDividend": 75.46,
    },
    {
      "id": "f90117d3-9bc0-4c28-98e3-4de75b2b271e",
      "name": "RRSP Ledger",
      "type": "RRSP",
      "totalValue": 340200.5,
      "totalChange": -1200.5,
      "totalChangePercent": -0.35,
      "annualDividend": 258.93,
    }
  ];

  // Mock stock listings
  final Map<String, List<Map<String, dynamic>>> _mockStocks = {
    "a9117be5-4ea5-419f-b778-be75b22b271d": [
      {
        "ticker": "AAPL",
        "name": "Apple Inc.",
        "shares": 10.5,
        "price": 185.0,
        "change": 1.24,
        "changePercent": 0.67,
        "currency": "USD",
        "value": 1942.5,
      },
      {
        "ticker": "XIU",
        "name": "iShares S&P/TSX 60 Index ETF",
        "shares": 100.25,
        "price": 32.5,
        "change": -0.15,
        "changePercent": -0.46,
        "currency": "CAD",
        "value": 3258.13,
      }
    ],
    "f90117d3-9bc0-4c28-98e3-4de75b2b271e": [
      {
        "ticker": "BHP",
        "name": "BHP Group Limited",
        "shares": 150.5,
        "price": 43.0,
        "change": 0.78,
        "changePercent": 1.85,
        "currency": "AUD",
        "value": 6471.5,
      },
      {
        "ticker": "BP",
        "name": "BP plc",
        "shares": 200.75,
        "price": 4.8,
        "change": -0.05,
        "changePercent": -1.03,
        "currency": "GBP",
        "value": 963.6,
      }
    ]
  };

  // Mock historical total valuations
  final Map<String, Map<String, List<Map<String, dynamic>>>> _mockValuationHistory = {
    "a9117be5-4ea5-419f-b778-be75b22b271d": {
      "NOW": [
        {"date": "Today", "value": 124500.2}
      ],
      "1D": [
        {"date": "09:30 AM", "value": 123800.0},
        {"date": "11:00 AM", "value": 124100.0},
        {"date": "01:00 PM", "value": 123900.0},
        {"date": "03:00 PM", "value": 124300.0},
        {"date": "04:00 PM", "value": 124500.2}
      ],
      "5D": [
        {"date": "Mon", "value": 122000.0},
        {"date": "Tue", "value": 123100.0},
        {"date": "Wed", "value": 122900.0},
        {"date": "Thu", "value": 124000.0},
        {"date": "Fri", "value": 124500.2}
      ],
      "1W": [
        {"date": "7d ago", "value": 121000.0},
        {"date": "5d ago", "value": 122500.0},
        {"date": "3d ago", "value": 124100.0},
        {"date": "Today", "value": 124500.2}
      ],
      "1M": [
        {"date": "Wk 1", "value": 119000.0},
        {"date": "Wk 2", "value": 121500.0},
        {"date": "Wk 3", "value": 120800.0},
        {"date": "Wk 4", "value": 124500.2}
      ],
      "3M": [
        {"date": "3m ago", "value": 115000.0},
        {"date": "2m ago", "value": 118000.0},
        {"date": "1m ago", "value": 121000.0},
        {"date": "Today", "value": 124500.2}
      ],
      "6M": [
        {"date": "6m ago", "value": 110000.0},
        {"date": "4m ago", "value": 114000.0},
        {"date": "2m ago", "value": 119000.0},
        {"date": "Today", "value": 124500.2}
      ],
      "1Y": [
        {"date": "Q1", "value": 110000.0},
        {"date": "Q2", "value": 115000.0},
        {"date": "Q3", "value": 118200.0},
        {"date": "Q4", "value": 124500.2}
      ],
      "5Y": [
        {"date": "5y ago", "value": 95000.0},
        {"date": "3y ago", "value": 108000.0},
        {"date": "1y ago", "value": 124500.2}
      ],
      "ALL": [
        {"date": "2021", "value": 50000.0},
        {"date": "2023", "value": 85000.0},
        {"date": "2025", "value": 118000.0},
        {"date": "Today", "value": 124500.2}
      ]
    },
    "f90117d3-9bc0-4c28-98e3-4de75b2b271e": {
      "NOW": [
        {"date": "Today", "value": 340200.5}
      ],
      "1D": [
        {"date": "09:30 AM", "value": 341000.0},
        {"date": "11:00 AM", "value": 339500.0},
        {"date": "01:00 PM", "value": 340100.0},
        {"date": "03:00 PM", "value": 339800.0},
        {"date": "04:00 PM", "value": 340200.5}
      ],
      "5D": [
        {"date": "Mon", "value": 338000.0},
        {"date": "Tue", "value": 339200.0},
        {"date": "Wed", "value": 340900.0},
        {"date": "Thu", "value": 339500.0},
        {"date": "Fri", "value": 340200.5}
      ],
      "1W": [
        {"date": "7d ago", "value": 335000.0},
        {"date": "5d ago", "value": 338000.0},
        {"date": "3d ago", "value": 339200.0},
        {"date": "Today", "value": 340200.5}
      ],
      "1M": [
        {"date": "Wk 1", "value": 332000.0},
        {"date": "Wk 2", "value": 335000.0},
        {"date": "Wk 3", "value": 338100.0},
        {"date": "Wk 4", "value": 340200.5}
      ],
      "3M": [
        {"date": "3m ago", "value": 325000.0},
        {"date": "2m ago", "value": 331000.0},
        {"date": "1m ago", "value": 336000.0},
        {"date": "Today", "value": 340200.5}
      ],
      "6M": [
        {"date": "6m ago", "value": 310000.0},
        {"date": "4m ago", "value": 320000.0},
        {"date": "2m ago", "value": 335000.0},
        {"date": "Today", "value": 340200.5}
      ],
      "1Y": [
        {"date": "Q1", "value": 310000.0},
        {"date": "Q2", "value": 322000.0},
        {"date": "Q3", "value": 331500.0},
        {"date": "Q4", "value": 340200.5}
      ],
      "5Y": [
        {"date": "5y ago", "value": 270000.0},
        {"date": "3y ago", "value": 295000.0},
        {"date": "1y ago", "value": 340200.5}
      ],
      "ALL": [
        {"date": "2019", "value": 180000.0},
        {"date": "2021", "value": 240000.0},
        {"date": "2023", "value": 310000.0},
        {"date": "Today", "value": 340200.5}
      ]
    }
  };

  // Mock historical accumulated dividends
  final Map<String, Map<String, List<Map<String, dynamic>>>> _mockDividendHistory = {
    "a9117be5-4ea5-419f-b778-be75b22b271d": {
      "NOW": [
        {"date": "Next Yr Proj.", "value": 75.46}
      ],
      "1Y": [
        {"date": "Last Yr Acc.", "value": 65.00},
        {"date": "Next Yr Proj.", "value": 75.46}
      ],
      "3Y": [
        {"date": "3 yrs ago", "value": 50.00},
        {"date": "2 yrs ago", "value": 58.00},
        {"date": "Last Yr", "value": 65.00},
        {"date": "Next Yr Proj.", "value": 75.46}
      ],
      "5Y": [
        {"date": "5 yrs ago", "value": 38.00},
        {"date": "3 yrs ago", "value": 50.00},
        {"date": "Last Yr", "value": 65.00},
        {"date": "Next Yr Proj.", "value": 75.46}
      ],
      "ALL": [
        {"date": "2021 Acc.", "value": 20.00},
        {"date": "2023 Acc.", "value": 45.00},
        {"date": "Last Yr", "value": 65.00},
        {"date": "Next Yr Proj.", "value": 75.46}
      ]
    },
    "f90117d3-9bc0-4c28-98e3-4de75b2b271e": {
      "NOW": [
        {"date": "Next Yr Proj.", "value": 258.93}
      ],
      "1Y": [
        {"date": "Last Yr Acc.", "value": 230.00},
        {"date": "Next Yr Proj.", "value": 258.93}
      ],
      "3Y": [
        {"date": "3 yrs ago", "value": 180.00},
        {"date": "2 yrs ago", "value": 210.00},
        {"date": "Last Yr", "value": 230.00},
        {"date": "Next Yr Proj.", "value": 258.93}
      ],
      "5Y": [
        {"date": "5 yrs ago", "value": 150.00},
        {"date": "3 yrs ago", "value": 180.00},
        {"date": "Last Yr", "value": 230.00},
        {"date": "Next Yr Proj.", "value": 258.93}
      ],
      "ALL": [
        {"date": "2019 Acc.", "value": 80.00},
        {"date": "2021 Acc.", "value": 140.00},
        {"date": "Last Yr", "value": 230.00},
        {"date": "Next Yr Proj.", "value": 258.93}
      ]
    }
  };

  // Convert local values in currencies AUD/GBP/USD to CAD equivalent
  double convertCurrencyToCAD(double amount, String currency) {
    if (currency == "CAD") return amount;
    if (currency == "USD") return amount * 1.35;
    if (currency == "AUD") return amount * 0.90;
    if (currency == "GBP") return amount * 1.75;
    return amount;
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Artificial network lag
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      "id": mockUserId,
      "name": "Jane Doe",
      "email": email,
    };
  }

  // Get investment profiles
  Future<List<InvestmentProfile>> getProfiles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!_isUsingMock) {
      try {
        final res = await http.get(Uri.parse("$baseUrl/holdings/projections/$mockUserId"))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          jsonDecode(res.body);
        }
      } catch (_) {
        _isUsingMock = true; // Fallback
      }
    }

    return _mockProfiles.map((p) {
      // Fetch dynamic stocks to populate profiles
      final stocksList = (_mockStocks[p["id"]] ?? [])
          .map((s) => StockHolding.fromJson(s))
          .toList();

      return InvestmentProfile(
        id: p["id"],
        name: p["name"],
        type: p["type"],
        totalValue: p["totalValue"],
        totalChange: p["totalChange"],
        totalChangePercent: p["totalChangePercent"],
        annualDividend: p["annualDividend"],
        stocks: stocksList,
      );
    }).toList();
  }

  // Get profile detail
  Future<InvestmentProfile> getProfileDetail(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final pMap = _mockProfiles.firstWhere((p) => p["id"] == profileId, orElse: () => _mockProfiles[0]);
    final stocksList = (_mockStocks[profileId] ?? [])
        .map((s) => StockHolding.fromJson(s))
        .toList();

    return InvestmentProfile(
      id: pMap["id"],
      name: pMap["name"],
      type: pMap["type"],
      totalValue: pMap["totalValue"],
      totalChange: pMap["totalChange"],
      totalChangePercent: pMap["totalChangePercent"],
      annualDividend: pMap["annualDividend"],
      stocks: stocksList,
    );
  }

  // Get historical chart coordinates
  Future<List<ChartPoint>> getChartPoints(String profileId, String interval, bool isDividend) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final source = isDividend ? _mockDividendHistory : _mockValuationHistory;
    final profileData = source[profileId] ?? {};
    final points = profileData[interval] ?? profileData["1Y"] ?? [];
    
    return points.map((pt) => ChartPoint.fromJson(pt)).toList();
  }

  // Add Buy Transaction (Import Form submission)
  Future<bool> addTransaction({
    required String profileId,
    required String ticker,
    required double quantity,
    required double price,
    required String currency,
    required String brokerage,
    required double fxRate,
    required String date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Calculate valuation and add to local mock data
    final stockVal = quantity * price;
    final newStock = {
      "ticker": ticker.toUpperCase(),
      "name": ticker.toUpperCase() == "AAPL" 
          ? "Apple Inc." 
          : ticker.toUpperCase() == "XIU" 
              ? "iShares S&P/TSX 60 Index" 
              : "Generic Asset",
      "shares": quantity,
      "price": price,
      "change": 0.0,
      "changePercent": 0.0,
      "currency": currency,
      "value": stockVal,
    };

    if (_mockStocks.containsKey(profileId)) {
      _mockStocks[profileId]!.add(newStock);
    } else {
      _mockStocks[profileId] = [newStock];
    }

    // Adjust profile total value
    final double addedValueCAD = convertCurrencyToCAD(stockVal, currency) * fxRate;
    final profileIdx = _mockProfiles.indexWhere((p) => p["id"] == profileId);
    if (profileIdx != -1) {
      _mockProfiles[profileIdx]["totalValue"] = (_mockProfiles[profileIdx]["totalValue"] as double) + addedValueCAD;
    }

    return true;
  }

  // Get dividend calendar events
  Future<List<DividendCalendarEvent>> getDividendCalendar(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!_isUsingMock) {
      try {
        final res = await http.get(Uri.parse("$baseUrl/holdings/dividends/calendar/$userId"))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body)["events"];
          return data.map((e) => DividendCalendarEvent.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint("Error fetching dividend calendar from backend: $e");
        // Fallback to mock on connection error
      }
    }

    return _mockDividendCalendar.map((e) => DividendCalendarEvent.fromJson(e)).toList();
  }

  // Get investment thesis
  Future<StockThesis?> getStockThesis(String userId, String stockId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_isUsingMock) {
      try {
        final res = await http.get(Uri.parse("$baseUrl/holdings/theses/$userId/$stockId"))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          return StockThesis.fromJson(jsonDecode(res.body));
        }
      } catch (e) {
        debugPrint("Error fetching stock thesis from backend: $e");
      }
    }

    if (_mockTheses.containsKey(stockId)) {
      return StockThesis.fromJson(_mockTheses[stockId]!);
    }
    return null;
  }

  // Save investment thesis
  Future<bool> saveStockThesis(String userId, String stockId, String thesisText, int intervalDays) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_isUsingMock) {
      try {
        final res = await http.post(
          Uri.parse("$baseUrl/holdings/theses"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "stock_id": stockId,
            "thesis_text": thesisText,
            "review_interval_days": intervalDays,
          }),
        ).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          // Sync back to mock data just in case
          _mockTheses[stockId] = jsonDecode(res.body);
          return true;
        }
      } catch (e) {
        debugPrint("Error saving stock thesis to backend: $e");
      }
    }

    // Mock implementation fallback
    final nowStr = DateTime.now().toUtc().toIso8601String();
    _mockTheses[stockId] = {
      "stock_id": stockId,
      "thesis_text": thesisText,
      "review_interval_days": intervalDays,
      "last_reviewed_at": nowStr,
      "updated_at": nowStr,
      "needs_review": false,
    };
    return true;
  }
}
