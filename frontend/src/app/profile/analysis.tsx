import React, { useEffect, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  SafeAreaView,
  Text,
  View,
} from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import Svg, { Circle } from "react-native-svg";

import { useAppTheme } from "@/context/ThemeContext";
import { apiService } from "@/services/api";

const getStockMetadata = (ticker: string) => {
  const t = ticker.toUpperCase().trim();
  if (t.includes("AAPL") || t.includes("MSFT") || t.includes("TSLA")) {
    return { sector: "Technology", dividendYield: 0.005 };
  }
  if (t.includes("XIU") || t.includes("RY") || t.includes("TD") || t.includes("BNS")) {
    return { sector: "Financials", dividendYield: 0.032 };
  }
  if (t.includes("BHP") || t.includes("RIO") || t.includes("VALE")) {
    return { sector: "Materials", dividendYield: 0.052 };
  }
  if (t.includes("BP") || t.includes("XOM") || t.includes("CVX") || t.includes("ENB")) {
    return { sector: "Energy", dividendYield: 0.046 };
  }
  return { sector: "Other", dividendYield: 0.02 };
};

const getStockValueInCAD = (stock: any) => {
  if (stock.currency === "CAD") return stock.value;
  if (stock.currency === "USD") return stock.value * 1.35;
  if (stock.currency === "AUD") return stock.value * 0.9;
  if (stock.currency === "GBP") return stock.value * 1.75;
  return stock.value;
};

const COLORS = ["#4CAF50", "#2196F3", "#9C27B0", "#FF9800", "#E91E63", "#00BCD4", "#8BC34A", "#3F51B5"];

interface AllocationItem {
  key: string;
  label: string;
  value: number;
  percentage: number;
  color: string;
  subText?: string;
}

export default function AnalysisDetailScreen() {
  const router = useRouter();
  const { id, type } = useLocalSearchParams<{ id: string; type: "stock" | "sector" | "dividend" }>();
  const { isDark } = useAppTheme();

  const [loading, setLoading] = useState(true);
  const [stockList, setStockList] = useState<any[]>([]);

  const fetchProfileData = async () => {
    if (!id) return;
    try {
      setLoading(true);
      // Fetch details (interval doesn't matter since we just need the stock holding array)
      const data = await apiService.getProfileDetail(id, "1Y");
      setStockList(data.stocks || []);
    } catch (err) {
      console.error("[AnalysisDetail] Error loading details:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfileData();
  }, [id]);

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "CAD",
      minimumFractionDigits: 2,
    }).format(val);
  };

  // Compute items dynamically depending on the selected Analysis Type
  let items: AllocationItem[] = [];
  let totalVal = 0;
  let titleStr = "Portfolio Analysis";

  if (type === "stock") {
    titleStr = "Stock Weight Details";
    totalVal = stockList.reduce((acc, s) => acc + getStockValueInCAD(s), 0);
    items = stockList
      .map((s, idx) => ({
        key: s.ticker,
        label: s.ticker,
        value: getStockValueInCAD(s),
        percentage: totalVal > 0 ? getStockValueInCAD(s) / totalVal : 0,
        color: COLORS[idx % COLORS.length],
        subText: `${s.shares} shares • ${s.name}`,
      }))
      .sort((a, b) => b.value - a.value);
  } else if (type === "sector") {
    titleStr = "Sector Exposure Details";
    const sectorGroups: Record<string, number> = {};
    stockList.forEach((s) => {
      const meta = getStockMetadata(s.ticker);
      const valCAD = getStockValueInCAD(s);
      sectorGroups[meta.sector] = (sectorGroups[meta.sector] || 0) + valCAD;
    });
    totalVal = Object.values(sectorGroups).reduce((a, b) => a + b, 0);
    items = Object.keys(sectorGroups)
      .map((sector, idx) => ({
        key: sector,
        label: sector,
        value: sectorGroups[sector],
        percentage: totalVal > 0 ? sectorGroups[sector] / totalVal : 0,
        color: COLORS[(idx + 2) % COLORS.length],
        subText: "Industry sector holdings weight",
      }))
      .sort((a, b) => b.value - a.value);
  } else if (type === "dividend") {
    titleStr = "Dividend Contributions";
    const dividendContributions = stockList.map((s) => {
      const meta = getStockMetadata(s.ticker);
      const valCAD = getStockValueInCAD(s);
      return {
        ticker: s.ticker,
        name: s.name,
        shares: s.shares,
        dividend: valCAD * meta.dividendYield,
        yieldPercent: (meta.dividendYield * 100).toFixed(1),
      };
    });
    totalVal = dividendContributions.reduce((acc, item) => acc + item.dividend, 0);
    items = dividendContributions
      .map((item, idx) => ({
        key: item.ticker,
        label: item.ticker,
        value: item.dividend,
        percentage: totalVal > 0 ? item.dividend / totalVal : 0,
        color: COLORS[(idx + 4) % COLORS.length],
        subText: `Yield: ${item.yieldPercent}% • Est. Annual Payout`,
      }))
      .sort((a, b) => b.value - a.value);
  }

  // Svg donut variables
  const r = 70;
  const strokeWidth = 22;
  const C = 2 * Math.PI * r; // 439.82
  let cumPercent = 0;

  return (
    <View
      className="flex-1"
      style={{ backgroundColor: isDark ? "#121212" : "#f5f5f5" }}
    >
      <SafeAreaView style={{ flex: 1, paddingHorizontal: 16 }}>
        {/* Header Bar */}
        <View className="flex-row items-center mt-6 mb-8">
          <Pressable
            className="w-10 h-10 border rounded-full items-center justify-center mr-4 active:opacity-90"
            style={{
              backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
              borderColor: isDark ? "#27272a" : "#e5e5e5",
            }}
            onPress={() => router.back()}
          >
            <Text
              className="text-base font-bold"
              style={{ color: isDark ? "#ffffff" : "#171717" }}
            >
              ←
            </Text>
          </Pressable>
          <View>
            <Text
              className="text-xl font-black"
              style={{ color: isDark ? "#ffffff" : "#171717" }}
            >
              {titleStr}
            </Text>
            <Text
              className="text-xs"
              style={{ color: isDark ? "#a3a3a3" : "#737373" }}
            >
              Allocation weight breakdown analysis
            </Text>
          </View>
        </View>

        {loading ? (
          <View className="flex-1 items-center justify-center">
            <ActivityIndicator size="large" color="#4CAF50" />
          </View>
        ) : (
          <FlatList
            data={items}
            keyExtractor={(item) => item.key}
            ListHeaderComponent={() => (
              <View className="items-center mb-10 mt-2">
                {/* Large Donut Ring */}
                <View style={{ width: 180, height: 180 }} className="justify-center items-center">
                  <Svg width={180} height={180} viewBox="0 0 180 180">
                    <Circle
                      cx="90"
                      cy="90"
                      r={r}
                      fill="transparent"
                      stroke={isDark ? "#1f2228" : "#e5e7eb"}
                      strokeWidth={strokeWidth}
                    />
                    {items.map((item) => {
                      const strokeOffset = -C * cumPercent;
                      const strokeDash = C * item.percentage;
                      cumPercent += item.percentage;

                      return (
                        <Circle
                          key={item.key}
                          cx="90"
                          cy="90"
                          r={r}
                          fill="transparent"
                          stroke={item.color}
                          strokeWidth={strokeWidth}
                          strokeDasharray={`${strokeDash} ${C}`}
                          strokeDashoffset={strokeOffset}
                          transform="rotate(-90 90 90)"
                        />
                      );
                    })}
                  </Svg>
                  {/* Central Text value inside Donut hole */}
                  <View className="absolute items-center">
                    <Text
                      className="text-[10px] font-bold uppercase tracking-wider"
                      style={{ color: isDark ? "#888c94" : "#6c727f" }}
                    >
                      Total Allocation
                    </Text>
                    <Text
                      className="text-base font-extrabold mt-1"
                      style={{ color: isDark ? "#ffffff" : "#171717" }}
                    >
                      {formatCurrency(totalVal)}
                    </Text>
                  </View>
                </View>
              </View>
            )}
            renderItem={({ item }) => (
              <View
                className="border p-4 rounded-2xl mb-3 flex-row justify-between items-center"
                style={{
                  backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                }}
              >
                <View className="flex-row items-center flex-1 mr-3">
                  {/* Color dot indicator */}
                  <View
                    className="w-4 h-4 rounded-full mr-3.5"
                    style={{ backgroundColor: item.color }}
                  />
                  <View className="flex-shrink-1">
                    <Text
                      className="font-bold text-sm"
                      style={{ color: isDark ? "#ffffff" : "#171717" }}
                    >
                      {item.label}
                    </Text>
                    {item.subText ? (
                      <Text
                        className="text-[10px] mt-0.5"
                        style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                        numberOfLines={1}
                      >
                        {item.subText}
                      </Text>
                    ) : null}
                  </View>
                </View>
                <View className="items-end">
                  <Text
                    className="font-semibold text-xs"
                    style={{ color: isDark ? "#ffffff" : "#171717" }}
                  >
                    {formatCurrency(item.value)}
                  </Text>
                  <Text
                    className="text-[10px] font-bold mt-0.5"
                    style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                  >
                    {(item.percentage * 100).toFixed(1)}%
                  </Text>
                </View>
              </View>
            )}
            ListEmptyComponent={() => (
              <View className="items-center justify-center py-12">
                <Text className="text-neutral-500 text-sm">
                  No allocations found.
                </Text>
              </View>
            )}
            contentContainerStyle={{ paddingBottom: 50 }}
            showsVerticalScrollIndicator={false}
          />
        )}
      </SafeAreaView>
    </View>
  );
}
