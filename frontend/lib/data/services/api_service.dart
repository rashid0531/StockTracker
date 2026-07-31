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

  ApiService() {
    _generateMockStocks();
  }

  // Mock dividend calendar events
  final List<Map<String, dynamic>> _mockDividendCalendar = [
    // 7 Same-Day Ex-Dividend Cluster on July 28, 2026
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
      "ticker": "MSFT",
      "stock_name": "Microsoft Corporation",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-08-14",
      "amount_per_share": 0.75,
      "shares_owned": 25.0,
      "projected_payout": 18.75,
      "currency": "USD",
    },
    {
      "ticker": "NVDA",
      "stock_name": "NVIDIA Corporation",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-08-18",
      "amount_per_share": 0.10,
      "shares_owned": 100.0,
      "projected_payout": 10.00,
      "currency": "USD",
    },
    {
      "ticker": "GOOGL",
      "stock_name": "Alphabet Inc.",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-08-20",
      "amount_per_share": 0.20,
      "shares_owned": 50.0,
      "projected_payout": 10.00,
      "currency": "USD",
    },
    {
      "ticker": "AMZN",
      "stock_name": "Amazon.com Inc.",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-08-22",
      "amount_per_share": 0.15,
      "shares_owned": 30.0,
      "projected_payout": 4.50,
      "currency": "USD",
    },
    {
      "ticker": "JPM",
      "stock_name": "JPMorgan Chase & Co.",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-08-31",
      "amount_per_share": 1.15,
      "shares_owned": 40.0,
      "projected_payout": 46.00,
      "currency": "USD",
    },
    {
      "ticker": "V",
      "stock_name": "Visa Inc.",
      "ex_dividend_date": "2026-07-28",
      "payment_date": "2026-09-01",
      "amount_per_share": 0.52,
      "shares_owned": 20.0,
      "projected_payout": 10.40,
      "currency": "USD",
    },

    // 7 Same-Day Payout Cluster on August 14, 2026
    {
      "ticker": "PG",
      "stock_name": "Procter & Gamble Co.",
      "ex_dividend_date": "2026-07-20",
      "payment_date": "2026-08-14",
      "amount_per_share": 1.00,
      "shares_owned": 35.0,
      "projected_payout": 35.00,
      "currency": "USD",
    },
    {
      "ticker": "KO",
      "stock_name": "The Coca-Cola Company",
      "ex_dividend_date": "2026-07-22",
      "payment_date": "2026-08-14",
      "amount_per_share": 0.485,
      "shares_owned": 80.0,
      "projected_payout": 38.80,
      "currency": "USD",
    },
    {
      "ticker": "PEP",
      "stock_name": "PepsiCo Inc.",
      "ex_dividend_date": "2026-07-22",
      "payment_date": "2026-08-14",
      "amount_per_share": 1.355,
      "shares_owned": 25.0,
      "projected_payout": 33.88,
      "currency": "USD",
    },
    {
      "ticker": "COST",
      "stock_name": "Costco Wholesale Corp.",
      "ex_dividend_date": "2026-07-25",
      "payment_date": "2026-08-14",
      "amount_per_share": 1.16,
      "shares_owned": 15.0,
      "projected_payout": 17.40,
      "currency": "USD",
    },
    {
      "ticker": "WMT",
      "stock_name": "Walmart Inc.",
      "ex_dividend_date": "2026-07-26",
      "payment_date": "2026-08-14",
      "amount_per_share": 0.2075,
      "shares_owned": 60.0,
      "projected_payout": 12.45,
      "currency": "USD",
    },

    // Additional stocks
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
      "ticker": "JNJ",
      "stock_name": "Johnson & Johnson",
      "ex_dividend_date": "2026-07-15",
      "payment_date": "2026-08-05",
      "amount_per_share": 1.24,
      "shares_owned": 40.0,
      "projected_payout": 49.60,
      "currency": "USD",
    },
    {
      "ticker": "RY",
      "stock_name": "Royal Bank of Canada",
      "ex_dividend_date": "2026-07-24",
      "payment_date": "2026-08-25",
      "amount_per_share": 1.38,
      "shares_owned": 50.0,
      "projected_payout": 69.00,
      "currency": "CAD",
    },
    {
      "ticker": "TD",
      "stock_name": "Toronto-Dominion Bank",
      "ex_dividend_date": "2026-08-04",
      "payment_date": "2026-08-31",
      "amount_per_share": 1.02,
      "shares_owned": 65.0,
      "projected_payout": 66.30,
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

  // User primary residential country & currency preferences
  String _userPrimaryCountry = "Canada";
  String _userPrimaryCurrency = "CAD";

  String get userPrimaryCountry => _userPrimaryCountry;
  String get userPrimaryCurrency => _userPrimaryCurrency;

  void setUserPrimaryPreferences({required String country, required String currency}) {
    _userPrimaryCountry = country;
    _userPrimaryCurrency = currency;
  }

  // Country-specific investment account types lookup
  static const Map<String, List<String>> countryAccountTypes = {
    "Canada": [
      "TFSA (Tax-Free Savings Account)",
      "RRSP (Registered Retirement Savings Plan)",
      "FHSA (First Home Savings Account)",
      "Non-Registered (Taxable)",
      "RESP (Registered Education Savings Plan)",
    ],
    "United States": [
      "Roth IRA",
      "Traditional IRA",
      "401(k) / 403(b)",
      "Taxable Brokerage",
      "HSA (Health Savings Account)",
    ],
    "United Kingdom": [
      "Stocks & Shares ISA",
      "SIPP (Self-Invested Personal Pension)",
      "GIA (General Investment Account)",
    ],
    "Australia": [
      "Superannuation Account",
      "Taxable Trading Account",
    ],
    "Germany": [
      "Depot (Taxable Brokerage)",
      "Private Altersvorsorge",
    ],
    "Global / Other": [
      "Taxable Brokerage Account",
      "Retirement Plan",
      "Savings & Investment",
    ],
  };

  // Mock profile definitions
  final List<Map<String, dynamic>> _mockProfiles = [
    {
      "id": "a9117be5-4ea5-419f-b778-be75b22b271d",
      "name": "TFSA Account",
      "type": "TFSA",
      "country": "Canada",
      "totalValue": 124500.2,
      "totalChange": 4500.2,
      "totalChangePercent": 3.75,
      "annualDividend": 75.46,
    },
    {
      "id": "f90117d3-9bc0-4c28-98e3-4de75b2b271e",
      "name": "RRSP Ledger",
      "type": "RRSP",
      "country": "Canada",
      "totalValue": 340200.5,
      "totalChange": -1200.5,
      "totalChangePercent": -0.35,
      "annualDividend": 258.93,
    }
  ];

  // Create new profile dynamically
  Future<InvestmentProfile> createProfile({
    required String name,
    required String country,
    required String type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newId = "prof-${DateTime.now().millisecondsSinceEpoch}";
    final newProfileMap = {
      "id": newId,
      "name": name,
      "country": country,
      "type": type,
      "totalValue": 0.0,
      "totalChange": 0.0,
      "totalChangePercent": 0.0,
      "annualDividend": 0.0,
    };
    _mockProfiles.add(newProfileMap);
    _mockStocks[newId] = [];
    return InvestmentProfile.fromJson(newProfileMap);
  }

  // Mock stock listings
  final Map<String, List<Map<String, dynamic>>> _mockStocks = {};

  // Mock historical total valuations
  final Map<String, Map<String, List<Map<String, dynamic>>>> _mockValuationHistory = {
    "a9117be5-4ea5-419f-b778-be75b22b271d": {
      "1W": [
        {"date": "Jul 24", "value": 121000.0},
        {"date": "Jul 25", "value": 121800.0},
        {"date": "Jul 26", "value": 122500.0},
        {"date": "Jul 27", "value": 123200.0},
        {"date": "Jul 28", "value": 124100.0},
        {"date": "Jul 29", "value": 123900.0},
        {"date": "Jul 30", "value": 124500.2}
      ],
      "6M": [
        {"date": "Feb 2026", "value": 110000.0},
        {"date": "Mar 2026", "value": 112500.0},
        {"date": "Apr 2026", "value": 115000.0},
        {"date": "May 2026", "value": 118200.0},
        {"date": "Jun 2026", "value": 121400.0},
        {"date": "Jul 2026", "value": 124500.2}
      ],
      "1Y": [
        {"date": "Aug 2025", "value": 102000.0},
        {"date": "Sep 2025", "value": 104500.0},
        {"date": "Oct 2025", "value": 106000.0},
        {"date": "Nov 2025", "value": 108500.0},
        {"date": "Dec 2025", "value": 110000.0},
        {"date": "Jan 2026", "value": 111200.0},
        {"date": "Feb 2026", "value": 113000.0},
        {"date": "Mar 2026", "value": 115500.0},
        {"date": "Apr 2026", "value": 117800.0},
        {"date": "May 2026", "value": 120100.0},
        {"date": "Jun 2026", "value": 122600.0},
        {"date": "Jul 2026", "value": 124500.2}
      ],
      "ALL": [
        {"date": "2021", "value": 45000.0},
        {"date": "2022", "value": 62000.0},
        {"date": "2023", "value": 84000.0},
        {"date": "2024", "value": 101000.0},
        {"date": "2025", "value": 115000.0},
        {"date": "2026 (Now)", "value": 124500.2}
      ]
    },
    "f90117d3-9bc0-4c28-98e3-4de75b2b271e": {
      "1W": [
        {"date": "Jul 24", "value": 334000.0},
        {"date": "Jul 25", "value": 335500.0},
        {"date": "Jul 26", "value": 337000.0},
        {"date": "Jul 27", "value": 338200.0},
        {"date": "Jul 28", "value": 339100.0},
        {"date": "Jul 29", "value": 338900.0},
        {"date": "Jul 30", "value": 340200.5}
      ],
      "6M": [
        {"date": "Feb 2026", "value": 312000.0},
        {"date": "Mar 2026", "value": 318000.0},
        {"date": "Apr 2026", "value": 324000.0},
        {"date": "May 2026", "value": 330000.0},
        {"date": "Jun 2026", "value": 335000.0},
        {"date": "Jul 2026", "value": 340200.5}
      ],
      "1Y": [
        {"date": "Aug 2025", "value": 290000.0},
        {"date": "Sep 2025", "value": 295000.0},
        {"date": "Oct 2025", "value": 300000.0},
        {"date": "Nov 2025", "value": 305000.0},
        {"date": "Dec 2025", "value": 310000.0},
        {"date": "Jan 2026", "value": 314000.0},
        {"date": "Feb 2026", "value": 319000.0},
        {"date": "Mar 2026", "value": 325000.0},
        {"date": "Apr 2026", "value": 330000.0},
        {"date": "May 2026", "value": 334000.0},
        {"date": "Jun 2026", "value": 338000.0},
        {"date": "Jul 2026", "value": 340200.5}
      ],
      "ALL": [
        {"date": "2020", "value": 160000.0},
        {"date": "2021", "value": 195000.0},
        {"date": "2022", "value": 230000.0},
        {"date": "2023", "value": 275000.0},
        {"date": "2024", "value": 310000.0},
        {"date": "2025", "value": 330000.0},
        {"date": "2026 (Now)", "value": 340200.5}
      ]
    }
  };

  // Mock historical accumulated dividends
  final Map<String, Map<String, List<Map<String, dynamic>>>> _mockDividendHistory = {
    "a9117be5-4ea5-419f-b778-be75b22b271d": {
      "1W": [
        {"date": "Jul 24", "value": 72.00},
        {"date": "Jul 25", "value": 72.50},
        {"date": "Jul 26", "value": 73.10},
        {"date": "Jul 27", "value": 73.80},
        {"date": "Jul 28", "value": 74.50},
        {"date": "Jul 29", "value": 75.00},
        {"date": "Jul 30", "value": 75.46}
      ],
      "6M": [
        {"date": "Feb 2026", "value": 66.00},
        {"date": "Mar 2026", "value": 68.00},
        {"date": "Apr 2026", "value": 70.00},
        {"date": "May 2026", "value": 72.00},
        {"date": "Jun 2026", "value": 74.00},
        {"date": "Jul 2026", "value": 75.46}
      ],
      "1Y": [
        {"date": "Aug 2025", "value": 55.00},
        {"date": "Sep 2025", "value": 57.00},
        {"date": "Oct 2025", "value": 59.00},
        {"date": "Nov 2025", "value": 61.00},
        {"date": "Dec 2025", "value": 63.00},
        {"date": "Jan 2026", "value": 65.00},
        {"date": "Feb 2026", "value": 67.00},
        {"date": "Mar 2026", "value": 69.00},
        {"date": "Apr 2026", "value": 71.00},
        {"date": "May 2026", "value": 73.00},
        {"date": "Jun 2026", "value": 74.50},
        {"date": "Jul 2026", "value": 75.46}
      ],
      "ALL": [
        {"date": "2021", "value": 20.00},
        {"date": "2022", "value": 35.00},
        {"date": "2023", "value": 45.00},
        {"date": "2024", "value": 58.00},
        {"date": "2025", "value": 68.00},
        {"date": "2026 (Now)", "value": 75.46}
      ]
    },
    "f90117d3-9bc0-4c28-98e3-4de75b2b271e": {
      "1W": [
        {"date": "Jul 24", "value": 250.00},
        {"date": "Jul 25", "value": 251.50},
        {"date": "Jul 26", "value": 253.00},
        {"date": "Jul 27", "value": 255.00},
        {"date": "Jul 28", "value": 256.80},
        {"date": "Jul 29", "value": 257.50},
        {"date": "Jul 30", "value": 258.93}
      ],
      "6M": [
        {"date": "Feb 2026", "value": 235.00},
        {"date": "Mar 2026", "value": 240.00},
        {"date": "Apr 2026", "value": 245.00},
        {"date": "May 2026", "value": 250.00},
        {"date": "Jun 2026", "value": 255.00},
        {"date": "Jul 2026", "value": 258.93}
      ],
      "1Y": [
        {"date": "Aug 2025", "value": 205.00},
        {"date": "Sep 2025", "value": 210.00},
        {"date": "Oct 2025", "value": 215.00},
        {"date": "Nov 2025", "value": 220.00},
        {"date": "Dec 2025", "value": 225.00},
        {"date": "Jan 2026", "value": 230.00},
        {"date": "Feb 2026", "value": 235.00},
        {"date": "Mar 2026", "value": 240.00},
        {"date": "Apr 2026", "value": 245.00},
        {"date": "May 2026", "value": 250.00},
        {"date": "Jun 2026", "value": 255.00},
        {"date": "Jul 2026", "value": 258.93}
      ],
      "ALL": [
        {"date": "2020", "value": 120.00},
        {"date": "2021", "value": 150.00},
        {"date": "2022", "value": 180.00},
        {"date": "2023", "value": 210.00},
        {"date": "2024", "value": 235.00},
        {"date": "2025", "value": 250.00},
        {"date": "2026 (Now)", "value": 258.93}
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

  double convertCurrencyToUSD(double amount, String currency) {
    if (currency == "USD") return amount;
    if (currency == "CAD") return amount / 1.35;
    if (currency == "AUD") return (amount * 0.90) / 1.35;
    if (currency == "GBP") return (amount * 1.75) / 1.35;
    return amount;
  }

  void _generateMockStocks() {
    final List<Map<String, dynamic>> tfsaList = [];
    final List<Map<String, dynamic>> rrspList = [];

    final List<List<dynamic>> tfsaData = [
      ["AAPL", "Apple Inc.", "USD", 185.00, 0.96, 12.0],
      ["XIU", "iShares S&P/TSX 60 ETF", "CAD", 32.50, 0.98, 150.0],
      ["SHOP", "Shopify Inc.", "CAD", 95.00, 0.00, 10.0],
      ["RY", "Royal Bank of Canada", "CAD", 140.00, 5.60, 20.0],
      ["TD", "Toronto-Dominion Bank", "CAD", 85.00, 4.08, 30.0],
      ["CNR", "Canadian National Railway", "CAD", 165.00, 3.36, 15.0],
      ["ENB", "Enbridge Inc.", "CAD", 48.00, 3.66, 80.0],
      ["CNQ", "Canadian Natural Resources", "CAD", 90.00, 4.00, 40.0],
      ["CP", "Canadian Pacific Kansas City", "CAD", 115.00, 0.76, 25.0],
      ["BNS", "Bank of Nova Scotia", "CAD", 65.00, 4.24, 35.0],
      ["BMO", "Bank of Montreal", "CAD", 120.00, 6.00, 18.0],
      ["BAM", "Brookfield Asset Management", "CAD", 50.00, 1.52, 50.0],
      ["SLF", "Sun Life Financial Inc.", "CAD", 70.00, 3.20, 22.0],
      ["ATD", "Alimentation Couche-Tard", "CAD", 78.00, 0.70, 30.0],
      ["NTR", "Nutrien Ltd.", "CAD", 75.00, 2.16, 20.0],
      ["CSU", "Constellation Software", "CAD", 3600.00, 4.00, 1.0],
      ["WCN", "Waste Connections Inc.", "CAD", 220.00, 1.15, 8.0],
      ["L", "Loblaw Companies Limited", "CAD", 145.00, 1.88, 12.0],
      ["FNV", "Franco-Nevada Corporation", "CAD", 160.00, 1.36, 10.0],
      ["WPM", "Wheaton Precious Metals", "CAD", 65.00, 0.60, 25.0],
      ["MG", "Magna International Inc.", "CAD", 55.00, 1.88, 40.0],
      ["IMO", "Imperial Oil Limited", "CAD", 85.00, 2.40, 15.0],
      ["CVE", "Cenovus Energy Inc.", "CAD", 25.00, 0.72, 100.0],
      ["GIB.A", "CGI Inc.", "CAD", 140.00, 0.00, 15.0],
      ["TECK.B", "Teck Resources Limited", "CAD", 60.00, 0.50, 30.0],
      ["POW", "Power Corporation of Canada", "CAD", 38.00, 2.10, 50.0],
      ["EMA", "Emera Incorporated", "CAD", 45.00, 2.87, 40.0],
      ["FTS", "Fortis Inc.", "CAD", 54.00, 2.36, 60.0],
      ["AEM", "Agnico Eagle Mines Limited", "CAD", 80.00, 1.60, 20.0],
      ["MFC", "Manulife Financial Corp.", "CAD", 32.00, 1.60, 120.0],
      ["QSR", "Restaurant Brands Intl", "CAD", 98.00, 2.32, 25.0],
      ["H", "Hydro One Limited", "CAD", 40.00, 1.20, 50.0],
      ["GIL", "Gildan Activewear Inc.", "CAD", 48.00, 0.82, 30.0],
      ["OTEX", "Open Text Corporation", "CAD", 42.00, 1.00, 45.0],
      ["DOL", "Dollarama Inc.", "CAD", 110.00, 0.30, 25.0],
    ];

    final List<List<dynamic>> rrspData = [
      ["BHP", "BHP Group Limited", "AUD", 43.00, 2.40, 150.5],
      ["BP", "BP plc", "GBP", 4.80, 0.28, 200.75],
      ["MSFT", "Microsoft Corporation", "USD", 420.00, 3.00, 15.0],
      ["JNJ", "Johnson & Johnson", "USD", 155.00, 4.96, 40.0],
      ["PG", "Procter & Gamble Co.", "USD", 160.00, 4.03, 35.0],
      ["KO", "The Coca-Cola Company", "USD", 62.00, 1.94, 100.0],
      ["PEP", "PepsiCo, Inc.", "USD", 170.00, 5.42, 30.0],
      ["JPM", "JPMorgan Chase & Co.", "USD", 195.00, 4.60, 25.0],
      ["XOM", "Exxon Mobil Corporation", "USD", 115.00, 3.80, 50.0],
      ["CVX", "Chevron Corporation", "USD", 150.00, 6.52, 20.0],
      ["MRK", "Merck & Co., Inc.", "USD", 125.00, 3.08, 45.0],
      ["ABBV", "AbbVie Inc.", "USD", 175.00, 6.20, 30.0],
      ["MCD", "McDonald's Corporation", "USD", 280.00, 6.68, 12.0],
      ["PFE", "Pfizer Inc.", "USD", 28.00, 1.68, 150.0],
      ["VZ", "Verizon Communications", "USD", 40.00, 2.66, 120.0],
      ["T", "AT&T Inc.", "USD", 18.00, 1.11, 200.0],
      ["HD", "Home Depot, Inc.", "USD", 350.00, 9.00, 10.0],
      ["LOW", "Lowe's Companies, Inc.", "USD", 220.00, 4.40, 15.0],
      ["MMM", "3M Company", "USD", 95.00, 6.04, 25.0],
      ["CAT", "Caterpillar Inc.", "USD", 330.00, 5.20, 8.0],
      ["DE", "Deere & Company", "USD", 380.00, 5.88, 6.0],
      ["HON", "Honeywell International", "USD", 200.00, 4.32, 12.0],
      ["GE", "General Electric Company", "USD", 150.00, 1.12, 25.0],
      ["IBM", "IBM Corporation", "USD", 185.00, 6.68, 18.0],
      ["CSCO", "Cisco Systems, Inc.", "USD", 48.00, 1.60, 75.0],
      ["TXN", "Texas Instruments Inc.", "USD", 175.00, 5.20, 14.0],
      ["PM", "Philip Morris International", "USD", 95.00, 5.20, 40.0],
      ["MO", "Altria Group, Inc.", "USD", 45.00, 3.92, 90.0],
      ["NKE", "NIKE, Inc.", "USD", 95.00, 1.48, 20.0],
      ["SBUX", "Starbucks Corporation", "USD", 85.00, 2.28, 30.0],
      ["Target", "Target Corporation", "USD", 145.00, 4.40, 25.0],
      ["CVS", "CVS Health Corporation", "USD", 75.00, 2.66, 35.0],
      ["WMT", "Walmart Inc.", "USD", 60.00, 0.83, 50.0],
      ["MDT", "Medtronic plc", "USD", 80.00, 2.76, 30.0],
      ["BAC", "Bank of America Corp.", "USD", 38.00, 0.96, 80.0],
    ];

    for (final s in tfsaData) {
      final ticker = s[0] as String;
      final name = s[1] as String;
      final currency = s[2] as String;
      final price = s[3] as double;
      final shares = s[5] as double;
      final change = (ticker.hashCode % 10 - 4) * 0.25;
      final changePercent = (change / price) * 100.0;
      tfsaList.add({
        "stock_id": getDeterministicStockId(ticker),
        "ticker": ticker,
        "name": name,
        "shares": shares,
        "price": price,
        "change": change,
        "changePercent": changePercent,
        "currency": currency,
        "value": shares * price,
      });
    }

    for (final s in rrspData) {
      final ticker = s[0] as String;
      final name = s[1] as String;
      final currency = s[2] as String;
      final price = s[3] as double;
      final shares = s[5] as double;
      final change = (ticker.hashCode % 10 - 4) * 0.25;
      final changePercent = (change / price) * 100.0;
      rrspList.add({
        "stock_id": getDeterministicStockId(ticker),
        "ticker": ticker,
        "name": name,
        "shares": shares,
        "price": price,
        "change": change,
        "changePercent": changePercent,
        "currency": currency,
        "value": shares * price,
      });
    }

    _mockStocks["a9117be5-4ea5-419f-b778-be75b22b271d"] = tfsaList;
    _mockStocks["f90117d3-9bc0-4c28-98e3-4de75b2b271e"] = rrspList;

    double tfsaTotalValue = 0;
    double tfsaTotalDividend = 0;
    for (final s in tfsaList) {
      final val = s["value"] as double;
      final currency = s["currency"] as String;
      tfsaTotalValue += convertCurrencyToCAD(val, currency);

      final ticker = s["ticker"] as String;
      final sourceItem = tfsaData.firstWhere((element) => element[0] == ticker);
      final divPerShare = sourceItem[4] as double;
      final shares = s["shares"] as double;
      tfsaTotalDividend += convertCurrencyToCAD(shares * divPerShare, currency);
    }

    double rrspTotalValue = 0;
    double rrspTotalDividend = 0;
    for (final s in rrspList) {
      final val = s["value"] as double;
      final currency = s["currency"] as String;
      rrspTotalValue += convertCurrencyToUSD(val, currency);

      final ticker = s["ticker"] as String;
      final sourceItem = rrspData.firstWhere((element) => element[0] == ticker);
      final divPerShare = sourceItem[4] as double;
      final shares = s["shares"] as double;
      rrspTotalDividend += convertCurrencyToUSD(shares * divPerShare, currency);
    }

    _mockProfiles[0]["totalValue"] = tfsaTotalValue;
    _mockProfiles[0]["annualDividend"] = tfsaTotalDividend;

    _mockProfiles[1]["totalValue"] = rrspTotalValue;
    _mockProfiles[1]["annualDividend"] = rrspTotalDividend;
  }

  // Mock Transaction Ledger
  final List<Map<String, dynamic>> _mockTransactions = [
    {
      "id": "tx-1",
      "profile_id": "a9117be5-4ea5-419f-b778-be75b22b271d",
      "profile_name": "TFSA Growth Portfolio",
      "ticker": "AAPL",
      "stock_name": "Apple Inc.",
      "transaction_type": "BUY",
      "quantity": 10.5,
      "price_per_share": 175.50,
      "total_amount": 1842.75,
      "currency": "USD",
      "transaction_date": "2026-07-28",
    },
    {
      "id": "tx-2",
      "profile_id": "a9117be5-4ea5-419f-b778-be75b22b271d",
      "profile_name": "TFSA Growth Portfolio",
      "ticker": "XIU",
      "stock_name": "iShares S&P/TSX 60 Index",
      "transaction_type": "BUY",
      "quantity": 100.0,
      "price_per_share": 34.20,
      "total_amount": 3420.00,
      "currency": "CAD",
      "transaction_date": "2026-07-25",
    },
    {
      "id": "tx-3",
      "profile_id": "f90117d3-9bc0-4c28-98e3-4de75b2b271e",
      "profile_name": "RRSP Retirement Nest",
      "ticker": "KO",
      "stock_name": "The Coca-Cola Company",
      "transaction_type": "BUY",
      "quantity": 80.0,
      "price_per_share": 62.00,
      "total_amount": 4960.00,
      "currency": "USD",
      "transaction_date": "2026-07-20",
    },
    {
      "id": "tx-4",
      "profile_id": "a9117be5-4ea5-419f-b778-be75b22b271d",
      "profile_name": "TFSA Growth Portfolio",
      "ticker": "BHP",
      "stock_name": "BHP Group Limited",
      "transaction_type": "SELL",
      "quantity": 5.0,
      "price_per_share": 58.00,
      "total_amount": 290.00,
      "currency": "USD",
      "transaction_date": "2026-07-15",
    },
  ];

  // Fetch transactions with optional filters
  Future<List<TransactionRecord>> getTransactions({
    String? profileId,
    String? type,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = List<Map<String, dynamic>>.from(_mockTransactions);

    if (profileId != null && profileId.isNotEmpty && profileId != "ALL") {
      results = results.where((t) => t["profile_id"] == profileId).toList();
    }
    if (type != null && type.isNotEmpty && type != "ALL") {
      results = results.where((t) => (t["transaction_type"] as String).toUpperCase() == type.toUpperCase()).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((t) {
        final ticker = (t["ticker"] as String).toLowerCase();
        final name = (t["stock_name"] as String).toLowerCase();
        return ticker.contains(q) || name.contains(q);
      }).toList();
    }

    return results.map((t) => TransactionRecord.fromJson(t)).toList();
  }

  // Execute Buy / Sell transaction and update stock holding + ledger
  Future<bool> executeBuySellTransaction({
    required String profileId,
    required String ticker,
    required String type, // "BUY" | "SELL"
    required double shares,
    required double price,
    required String currency,
    String? date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final profile = _mockProfiles.firstWhere((p) => p["id"] == profileId, orElse: () => _mockProfiles[0]);
    final profileName = profile["name"] as String;
    final stocksList = _mockStocks[profileId] ?? [];

    final existingIdx = stocksList.indexWhere((s) => s["ticker"].toString().toUpperCase() == ticker.toUpperCase());

    if (type.toUpperCase() == "BUY") {
      if (existingIdx != -1) {
        final existing = stocksList[existingIdx];
        final newShares = (existing["shares"] as double) + shares;
        existing["shares"] = newShares;
        existing["value"] = newShares * price;
      } else {
        stocksList.add({
          "stock_id": getDeterministicStockId(ticker),
          "ticker": ticker.toUpperCase(),
          "name": "$ticker Holding",
          "shares": shares,
          "price": price,
          "change": 0.0,
          "changePercent": 0.0,
          "currency": currency,
          "value": shares * price,
        });
      }
    } else if (type.toUpperCase() == "SELL") {
      if (existingIdx != -1) {
        final existing = stocksList[existingIdx];
        final currentShares = existing["shares"] as double;
        final newShares = (currentShares - shares).clamp(0.0, double.infinity);
        if (newShares <= 0) {
          stocksList.removeAt(existingIdx);
        } else {
          existing["shares"] = newShares;
          existing["value"] = newShares * price;
        }
      }
    }

    // Add entry to transaction ledger
    final String dateStr = date ?? "2026-07-30";
    _mockTransactions.insert(0, {
      "id": "tx-${DateTime.now().millisecondsSinceEpoch}",
      "profile_id": profileId,
      "profile_name": profileName,
      "ticker": ticker.toUpperCase(),
      "stock_name": "$ticker Holding",
      "transaction_type": type.toUpperCase(),
      "quantity": shares,
      "price_per_share": price,
      "total_amount": shares * price,
      "currency": currency,
      "transaction_date": dateStr,
    });

    // Update profile total valuation
    double totalValCAD = 0;
    for (var s in stocksList) {
      final val = s["value"] as double;
      final curr = s["currency"] as String;
      totalValCAD += convertCurrencyToCAD(val, curr);
    }
    profile["totalValue"] = totalValCAD;

    return true;
  }
}
