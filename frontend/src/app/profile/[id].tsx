import React, { useEffect, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  SafeAreaView,
  ScrollView,
  Text,
  View,
} from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import Svg, { Defs, LinearGradient, Path, Stop, Text as SvgText, Rect, Circle } from "react-native-svg";

import { apiService } from "@/services/api";
import { useAppTheme } from "@/context/ThemeContext";

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

interface DonutChartItem {
  key: string;
  label: string;
  value: number;
  percentage: number;
  color: string;
}

const GridDonutChart = ({
  items,
  title,
  subtitle,
  centerLabel,
  onPress,
}: {
  items: DonutChartItem[];
  title: string;
  subtitle: string;
  centerLabel: string;
  onPress: () => void;
}) => {
  const { isDark } = useAppTheme();
  const r = 34;
  const strokeWidth = 10;
  const C = 2 * Math.PI * r;

  let cumPercent = 0;

  // Show top 3 holdings/sectors inside the card legend
  const topItems = items.slice(0, 3);

  return (
    <Pressable
      className="flex-1 border p-4 rounded-3xl items-center active:opacity-90 shadow-md"
      style={{
        backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
        borderColor: isDark ? "#27272a" : "#e5e5e5",
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: isDark ? 0.2 : 0.05,
        shadowRadius: 4,
        elevation: 2,
      }}
      onPress={onPress}
    >
      <View style={{ width: 100, height: 100 }} className="justify-center items-center">
        <Svg width={100} height={100} viewBox="0 0 100 100">
          <Circle
            cx="50"
            cy="50"
            r={r}
            fill="transparent"
            stroke={isDark ? "#2d3139" : "#f3f4f6"}
            strokeWidth={strokeWidth}
          />
          {items.map((item, idx) => {
            const strokeOffset = -C * cumPercent;
            const strokeDash = C * item.percentage;
            cumPercent += item.percentage;

            return (
              <Circle
                key={item.key}
                cx="50"
                cy="50"
                r={r}
                fill="transparent"
                stroke={item.color}
                strokeWidth={strokeWidth}
                strokeDasharray={`${strokeDash} ${C}`}
                strokeDashoffset={strokeOffset}
                transform="rotate(-90 50 50)"
              />
            );
          })}
        </Svg>
        {/* Center Label inside Donut Hole */}
        <View className="absolute items-center">
          <Text
            className="text-[9px] font-extrabold uppercase tracking-wide"
            style={{ color: isDark ? "#ffffff" : "#171717" }}
          >
            {centerLabel}
          </Text>
        </View>
      </View>

      <Text
        className="text-xs font-black mt-3 text-center"
        style={{ color: isDark ? "#ffffff" : "#171717" }}
      >
        {title}
      </Text>

      {/* Mini Detailed Legend */}
      <View className="w-full mt-3 pl-1" style={{ gap: 4 }}>
        {topItems.map((item) => (
          <View key={item.key} className="flex-row items-center justify-between">
            <View className="flex-row items-center flex-1 mr-1">
              <View
                className="w-1.5 h-1.5 rounded-full mr-1.5"
                style={{ backgroundColor: item.color }}
              />
              <Text
                className="text-[9px] font-bold"
                style={{ color: isDark ? "#ffffff" : "#171717" }}
                numberOfLines={1}
              >
                {item.label}
              </Text>
            </View>
            <Text
              className="text-[9px] font-extrabold"
              style={{ color: isDark ? "#a3a3a3" : "#737373" }}
            >
              {(item.percentage * 100).toFixed(0)}%
            </Text>
          </View>
        ))}
      </View>
    </Pressable>
  );
};

const getIntervalsForMode = (mode: "VALUATION" | "DIVIDEND") => {
  return mode === "VALUATION"
    ? ["NOW", "1D", "5D", "1W", "1M", "3M", "6M", "1Y", "5Y", "ALL"]
    : ["NOW", "1Y", "3Y", "5Y", "ALL"];
};

export default function ProfileDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark } = useAppTheme();

  // Chart Layout Constants
  const width = 340;
  const height = 200;
  const paddingLeft = 55;
  const paddingRight = 15;
  const paddingTop = 15;
  const paddingBottom = 25;
  const chartWidth = width - paddingLeft - paddingRight;
  const chartHeight = height - paddingTop - paddingBottom;

  const [activeInterval, setActiveInterval] = useState("1Y");
  const [activeTab, setActiveTab] = useState<"PERFORMANCE" | "ANALYTICS">("PERFORMANCE");
  const [chartMode, setChartMode] = useState<"VALUATION" | "DIVIDEND">("VALUATION");
  const [loading, setLoading] = useState(true);
  const [stockList, setStockList] = useState<any[]>([]);
  const [chartPoints, setChartPoints] = useState<any[]>([]);
  const [dividendPoints, setDividendPoints] = useState<any[]>([]);
  const [selectedPoint, setSelectedPoint] = useState<any>(null);

  const intervals = getIntervalsForMode(chartMode);

  useEffect(() => {
    const validIntervals = getIntervalsForMode(chartMode);
    if (!validIntervals.includes(activeInterval)) {
      setActiveInterval("1Y");
    }
  }, [chartMode]);

  const handleTouch = (evt: any) => {
    const activePoints = chartMode === "VALUATION" ? chartPoints : dividendPoints;
    if (activePoints.length === 0) return;

    // Get touch X coordinate relative to the SVG container container
    const touchX = evt.nativeEvent.locationX;

    // Map data to SVG viewport points (same logic as inside Svg)
    const points = activePoints.map((p, idx) => {
      const x = activePoints.length > 1
        ? paddingLeft + (idx * chartWidth) / (activePoints.length - 1)
        : paddingLeft + chartWidth / 2;
      return { ...p, x };
    });

    // Find the point closest to touchX
    let closestPoint = points[0];
    let minDiff = Math.abs(points[0].x - touchX);
    for (let i = 1; i < points.length; i++) {
      const diff = Math.abs(points[i].x - touchX);
      if (diff < minDiff) {
        minDiff = diff;
        closestPoint = points[i];
      }
    }

    setSelectedPoint(closestPoint);
  };

  const fetchProfileData = async () => {
    if (!id) return;
    try {
      setLoading(true);
      const data = await apiService.getProfileDetail(id, activeInterval);
      setStockList(data.stocks);
      setChartPoints(data.chartPoints);
      setDividendPoints(data.dividendChartPoints || []);

      const activePoints =
        chartMode === "VALUATION" ? data.chartPoints : data.dividendChartPoints || [];
      if (activePoints.length > 0) {
        setSelectedPoint(activePoints[activePoints.length - 1]);
      }
    } catch (err) {
      console.error("[ProfileDetail] Error fetching details:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfileData();
  }, [id, activeInterval]);

  useEffect(() => {
    const activePoints = chartMode === "VALUATION" ? chartPoints : dividendPoints;
    if (activePoints.length > 0) {
      setSelectedPoint(activePoints[activePoints.length - 1]);
    }
  }, [chartMode]);

  const formatCurrency = (val: number, currency: string) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: currency,
      minimumFractionDigits: 2,
    }).format(val);
  };

  // 1. Stock Allocations by Ticker
  const totalStockValue = stockList.reduce((acc, s) => acc + getStockValueInCAD(s), 0);
  const stockAllocItems = stockList
    .map((s, idx) => ({
      key: s.ticker,
      label: s.ticker,
      value: getStockValueInCAD(s),
      percentage: totalStockValue > 0 ? getStockValueInCAD(s) / totalStockValue : 0,
      color: COLORS[idx % COLORS.length],
    }))
    .sort((a, b) => b.value - a.value);

  // 2. Stock Allocations by Sector
  const sectorGroups: Record<string, number> = {};
  stockList.forEach((s) => {
    const meta = getStockMetadata(s.ticker);
    const valCAD = getStockValueInCAD(s);
    sectorGroups[meta.sector] = (sectorGroups[meta.sector] || 0) + valCAD;
  });
  const totalSectorValue = Object.values(sectorGroups).reduce((a, b) => a + b, 0);
  const sectorAllocItems = Object.keys(sectorGroups)
    .map((sector, idx) => ({
      key: sector,
      label: sector,
      value: sectorGroups[sector],
      percentage: totalSectorValue > 0 ? sectorGroups[sector] / totalSectorValue : 0,
      color: COLORS[(idx + 2) % COLORS.length],
    }))
    .sort((a, b) => b.value - a.value);

  // 3. Dividend contributions by Ticker
  const dividendContributions = stockList.map((s) => {
    const meta = getStockMetadata(s.ticker);
    const valCAD = getStockValueInCAD(s);
    return {
      ticker: s.ticker,
      dividend: valCAD * meta.dividendYield,
    };
  });
  const totalDividendValue = dividendContributions.reduce((acc, item) => acc + item.dividend, 0);
  const dividendContribItems = dividendContributions
    .map((item, idx) => ({
      key: item.ticker,
      label: item.ticker,
      value: item.dividend,
      percentage: totalDividendValue > 0 ? item.dividend / totalDividendValue : 0,
      color: COLORS[(idx + 4) % COLORS.length],
    }))
    .sort((a, b) => b.value - a.value);

  const renderChart = () => {
    const activePoints = chartMode === "VALUATION" ? chartPoints : dividendPoints;
    if (activePoints.length === 0) return null;

    const values = activePoints.map((p) => p.value);
    const minVal = Math.min(...values);
    const maxVal = Math.max(...values);
    const valRange = maxVal - minVal || 1;

    // Map data to SVG viewport points
    const points = activePoints.map((p, idx) => {
      const x =
        activePoints.length > 1
          ? paddingLeft + (idx * chartWidth) / (activePoints.length - 1)
          : paddingLeft + chartWidth / 2;
      const y =
        valRange > 0
          ? (height - paddingBottom) - ((p.value - minVal) * chartHeight) / valRange
          : paddingTop + chartHeight / 2;
      return { x, y, value: p.value, date: p.date };
    });

    const selectedPointIdx = activePoints.findIndex((p) => p.date === selectedPoint?.date);
    const selectedPtCoords = selectedPointIdx !== -1 ? points[selectedPointIdx] : points[points.length - 1];

    // Create stroke path string
    let pathD = `M ${points[0].x} ${points[0].y}`;
    for (let i = 1; i < points.length; i++) {
      pathD += ` L ${points[i].x} ${points[i].y}`;
    }

    // Create closed path string for area gradient
    const areaD =
      points.length > 1
        ? `${pathD} L ${points[points.length - 1].x} ${height - paddingBottom} L ${points[0].x} ${height - paddingBottom} Z`
        : "";

    const strokeColor = chartMode === "VALUATION" ? "#4CAF50" : "#FFB300";
    const gradientId = chartMode === "VALUATION" ? "chartGradient" : "dividendGradient";

    const formatLabelVal = (val: number) => {
      if (val >= 1000000) return `$${(val / 1000000).toFixed(1)}M`;
      if (val >= 1000) return `$${(val / 1000).toFixed(0)}k`;
      return `$${val.toFixed(0)}`;
    };

    const gridLines = [
      { y: paddingTop, val: maxVal },
      { y: paddingTop + chartHeight / 2, val: (minVal + maxVal) / 2 },
      { y: height - paddingBottom, val: minVal },
    ];

    const xLabels: { x: number; text: string }[] = [];
    if (points.length > 0) {
      xLabels.push({ x: points[0].x, text: points[0].date });
      if (points.length > 2) {
        const midIdx = Math.floor(points.length / 2);
        xLabels.push({ x: points[midIdx].x, text: points[midIdx].date });
      }
      if (points.length > 1) {
        xLabels.push({ x: points[points.length - 1].x, text: points[points.length - 1].date });
      }
    }

    return (
      <View
        className="items-center border p-4 rounded-3xl"
        style={{
          backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
          borderColor: isDark ? "#27272a" : "#e5e5e5",
          shadowColor: "#000",
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: isDark ? 0.3 : 0.08,
          shadowRadius: 12,
          elevation: 3,
        }}
      >
        <View className="items-center mb-4">
          <Text
            className="text-xs font-semibold"
            style={{ color: isDark ? "#a3a3a3" : "#737373" }}
          >
            {selectedPoint
              ? chartMode === "VALUATION"
                ? `Interval Value (${selectedPoint.date})`
                : `Est. Annual Dividend (${selectedPoint.date})`
              : "Select a point"}
          </Text>
          <Text
            className="text-2xl font-black mt-0.5"
            style={{ color: isDark ? "#ffffff" : "#171717" }}
          >
            {selectedPoint ? formatCurrency(selectedPoint.value, "CAD") : "—"}
          </Text>
        </View>

        <View
          style={{ width: width, height: height }}
          onStartShouldSetResponder={() => true}
          onMoveShouldSetResponder={() => true}
          onResponderGrant={handleTouch}
          onResponderMove={handleTouch}
        >
          <View pointerEvents="none">
            <Svg width={width} height={height} viewBox={`0 0 ${width} ${height}`}>
              <Defs>
                <LinearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
                  <Stop offset="0%" stopColor="#4CAF50" stopOpacity="0.25" />
                  <Stop offset="100%" stopColor="#4CAF50" stopOpacity="0.0" />
                </LinearGradient>
                <LinearGradient id="dividendGradient" x1="0" y1="0" x2="0" y2="1">
                  <Stop offset="0%" stopColor="#FFB300" stopOpacity="0.25" />
                  <Stop offset="100%" stopColor="#FFB300" stopOpacity="0.0" />
                </LinearGradient>
              </Defs>

              {gridLines.map((line, idx) => (
                <React.Fragment key={`grid-${idx}`}>
                  <Path
                    d={`M ${paddingLeft} ${line.y} L ${width - paddingRight} ${line.y}`}
                    stroke={isDark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.04)"}
                    strokeWidth="1"
                  />
                  <SvgText
                    x={paddingLeft - 8}
                    y={line.y + 3}
                    fill={isDark ? "#888c94" : "#6c727f"}
                    fontSize="9"
                    fontWeight="600"
                    textAnchor="end"
                  >
                    {formatLabelVal(line.val)}
                  </SvgText>
                </React.Fragment>
              ))}

              {xLabels.map((label, idx) => (
                <SvgText
                  key={`x-lbl-${idx}`}
                  x={label.x}
                  y={height - 8}
                  fill={isDark ? "#888c94" : "#6c727f"}
                  fontSize="9"
                  fontWeight="600"
                  textAnchor="middle"
                >
                  {label.text}
                </SvgText>
              ))}

              <Path d={areaD} fill={`url(#${gradientId})`} />

              <Path
                d={pathD}
                fill="none"
                stroke={strokeColor}
                strokeWidth="3.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />

              {selectedPtCoords && (
                <React.Fragment>
                  <Path
                    d={`M ${selectedPtCoords.x} ${paddingTop} L ${selectedPtCoords.x} ${height - paddingBottom}`}
                    stroke={strokeColor}
                    strokeWidth="1.25"
                    strokeDasharray="4 4"
                  />
                  <Path
                    d={`M ${paddingLeft} ${selectedPtCoords.y} L ${width - paddingRight} ${selectedPtCoords.y}`}
                    stroke={strokeColor}
                    strokeWidth="1.25"
                    strokeDasharray="4 4"
                  />

                  <Path
                    d={`M ${selectedPtCoords.x} ${selectedPtCoords.y} m -5, 0 a 5,5 0 1,0 10,0 a 5,5 0 1,0 -10,0`}
                    fill="#ffffff"
                    stroke={strokeColor}
                    strokeWidth="3"
                  />

                  <Rect
                    x={2}
                    y={selectedPtCoords.y - 9}
                    width={48}
                    height={18}
                    rx={4}
                    ry={4}
                    fill={strokeColor}
                  />
                  <SvgText
                    x={26}
                    y={selectedPtCoords.y + 3}
                    fill="#ffffff"
                    fontSize="8"
                    fontWeight="800"
                    textAnchor="middle"
                  >
                    {formatLabelVal(selectedPtCoords.value)}
                  </SvgText>

                  <Rect
                    x={selectedPtCoords.x - 22.5}
                    y={height - paddingBottom + 2}
                    width={45}
                    height={16}
                    rx={4}
                    ry={4}
                    fill={isDark ? "#2d3139" : "#e5e7eb"}
                  />
                  <SvgText
                    x={selectedPtCoords.x}
                    y={height - paddingBottom + 13}
                    fill={isDark ? "#ffffff" : "#171717"}
                    fontSize="8"
                    fontWeight="800"
                    textAnchor="middle"
                  >
                    {selectedPtCoords.date}
                  </SvgText>
                </React.Fragment>
              )}
            </Svg>
          </View>
        </View>
      </View>
    );
  };

  return (
    <View
      className="flex-1"
      style={{ backgroundColor: isDark ? "#121212" : "#f5f5f5" }}
    >
      <SafeAreaView style={{ flex: 1, paddingHorizontal: 16 }}>
        {/* Header Bar */}
        <View className="flex-row items-center justify-between mt-6 mb-4">
          <View className="flex-row items-center">
            <Pressable
              className="w-10 h-10 border rounded-full items-center justify-center mr-4 active:opacity-90"
              style={{
                backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                borderColor: isDark ? "#27272a" : "#e5e5e5",
              }}
              onPress={() => {
                if (router.canGoBack()) {
                  router.back();
                } else {
                  router.replace("/dashboard");
                }
              }}
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
                Profile Details
              </Text>
              <Text
                className="text-xs"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Portfolio Breakdown & History
              </Text>
            </View>
          </View>

          {/* Home Button */}
          <Pressable
            className="w-10 h-10 border rounded-full items-center justify-center active:opacity-90"
            style={{
              backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
              borderColor: isDark ? "#27272a" : "#e5e5e5",
            }}
            onPress={() => router.replace("/dashboard")}
          >
            <Text
              className="text-lg"
              style={{ color: isDark ? "#ffffff" : "#171717" }}
            >
              🏠
            </Text>
          </Pressable>
        </View>

        {/* Tab Selector */}
        <View
          className="flex-row border-b mb-6 mt-2"
          style={{ borderBottomColor: isDark ? "#27272a" : "#e5e5e5" }}
        >
          {(["Performance", "Analytics"] as const).map((tab) => {
            const tabKey = tab.toUpperCase() as "PERFORMANCE" | "ANALYTICS";
            const isActive = activeTab === tabKey;
            return (
              <Pressable
                key={tab}
                className="flex-1 py-3 items-center"
                style={{
                  borderBottomWidth: isActive ? 2 : 0,
                  borderBottomColor: isActive ? "#4CAF50" : "transparent",
                }}
                onPress={() => setActiveTab(tabKey)}
              >
                <Text
                  className="text-sm font-bold"
                  style={{
                    color: isActive
                      ? isDark
                        ? "#ffffff"
                        : "#171717"
                      : isDark
                      ? "#888c94"
                      : "#6c727f",
                  }}
                >
                  {tab}
                </Text>
              </Pressable>
            );
          })}
        </View>

        {loading ? (
          <View className="flex-1 items-center justify-center">
            <ActivityIndicator size="large" color="#4CAF50" />
          </View>
        ) : activeTab === "PERFORMANCE" ? (
          <FlatList
            data={stockList}
            keyExtractor={(item) => item.ticker}
            ListHeaderComponent={() => (
              <View className="mb-6">
                {/* Responsive SVG Chart */}
                {renderChart()}

                {/* Chart Mode Toggle */}
                <View
                  className="flex-row justify-around border rounded-2xl p-1.5 mt-4"
                  style={{
                    backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                    borderColor: isDark ? "#27272a" : "#e5e5e5",
                    shadowColor: "#000",
                    shadowOffset: { width: 0, height: 1 },
                    shadowOpacity: isDark ? 0.1 : 0.03,
                    shadowRadius: 2,
                    elevation: 1,
                  }}
                >
                  <Pressable
                    className={`flex-1 py-2 rounded-xl items-center ${
                      chartMode === "VALUATION" ? "bg-positive" : ""
                    }`}
                    onPress={() => setChartMode("VALUATION")}
                  >
                    <Text
                      className="text-xs font-bold"
                      style={{
                        color: chartMode === "VALUATION" ? "#ffffff" : (isDark ? "#a3a3a3" : "#737373"),
                      }}
                    >
                      Valuation
                    </Text>
                  </Pressable>
                  <Pressable
                    className={`flex-1 py-2 rounded-xl items-center ${
                      chartMode === "DIVIDEND" ? "bg-amber-500" : ""
                    }`}
                    onPress={() => setChartMode("DIVIDEND")}
                  >
                    <Text
                      className="text-xs font-bold"
                      style={{
                        color: chartMode === "DIVIDEND" ? "#ffffff" : (isDark ? "#a3a3a3" : "#737373"),
                      }}
                    >
                      Dividend Income
                    </Text>
                  </Pressable>
                </View>

                {/* Interval scroll selector */}
                <View
                  className="border rounded-2xl p-1.5 mt-4"
                  style={{
                    backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                    borderColor: isDark ? "#27272a" : "#e5e5e5",
                    shadowColor: "#000",
                    shadowOffset: { width: 0, height: 1 },
                    shadowOpacity: isDark ? 0.1 : 0.03,
                    shadowRadius: 2,
                    elevation: 1,
                  }}
                >
                  <ScrollView
                    horizontal
                    showsHorizontalScrollIndicator={false}
                    contentContainerStyle={{ paddingHorizontal: 4, gap: 6 }}
                  >
                    {intervals.map((interval) => (
                      <Pressable
                        key={interval}
                        className="px-4 py-2 rounded-xl items-center"
                        style={{
                          backgroundColor:
                            activeInterval === interval
                              ? chartMode === "VALUATION"
                                ? "#4CAF50"
                                : "#FFB300"
                              : "transparent",
                        }}
                        onPress={() => setActiveInterval(interval)}
                      >
                        <Text
                          className="text-xs font-bold"
                          style={{
                            color: activeInterval === interval ? "#ffffff" : isDark ? "#a3a3a3" : "#737373",
                          }}
                        >
                          {interval}
                        </Text>
                      </Pressable>
                    ))}
                  </ScrollView>
                </View>

                <Text
                  className="text-xs font-bold uppercase tracking-widest mt-6 mb-3 pl-1"
                  style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                >
                  Active Allocations
                </Text>
              </View>
            )}
            renderItem={({ item }) => {
              const isPositive = item.change >= 0;
              return (
                <View
                  className="border p-4 rounded-2xl mb-3 flex-row justify-between items-center"
                  style={{
                    backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                    borderColor: isDark ? "#27272a" : "#e5e5e5",
                    shadowColor: "#000",
                    shadowOffset: { width: 0, height: 2 },
                    shadowOpacity: isDark ? 0.2 : 0.04,
                    shadowRadius: 4,
                    elevation: 2,
                  }}
                >
                  {/* Left Section: circular icon and ticker */}
                  <View className="flex-row items-center flex-1 mr-2">
                    <View
                      className="w-11 h-11 border rounded-full items-center justify-center mr-3"
                      style={{
                        backgroundColor: isDark ? "#171717" : "#fafafa",
                        borderColor: isDark ? "#27272a" : "#e5e5e5",
                      }}
                    >
                      <Text
                        className="font-extrabold text-sm uppercase"
                        style={{ color: isDark ? "#ffffff" : "#171717" }}
                      >
                        {item.ticker.substring(0, 2)}
                      </Text>
                    </View>
                    <View className="flex-shrink-1">
                      <Text
                        className="font-bold text-sm"
                        style={{ color: isDark ? "#ffffff" : "#171717" }}
                      >
                        {item.ticker}
                      </Text>
                      <Text
                        className="text-[10px] mt-0.5"
                        style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                        numberOfLines={1}
                      >
                        {item.name}
                      </Text>
                    </View>
                  </View>

                  {/* Middle Section: Shares Owned */}
                  <View className="items-start min-w-[70px] mr-2">
                    <Text
                      className="text-xs font-semibold"
                      style={{ color: isDark ? "#ffffff" : "#171717" }}
                    >
                      {item.shares}
                    </Text>
                    <Text
                      className="text-[10px] mt-0.5"
                      style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                    >
                      shares
                    </Text>
                  </View>

                  {/* Right Section: live price, daily change percentage badge, subtotal */}
                  <View className="items-end">
                    <Text
                      className="text-xs font-semibold"
                      style={{ color: isDark ? "#ffffff" : "#171717" }}
                    >
                      {formatCurrency(item.price, item.currency)}
                    </Text>
                    <View
                      className={`px-2 py-0.5 rounded-md mt-1 ${
                        isPositive ? "bg-positive/10 border border-positive/20" : "bg-negative/10 border border-negative/20"
                      }`}
                    >
                      <Text
                        className={`text-[9px] font-bold ${
                          isPositive ? "text-positive" : "text-negative"
                        }`}
                      >
                        {isPositive ? "+" : ""}{item.changePercent}%
                      </Text>
                    </View>
                    <Text
                      className="text-[10px] mt-1 font-bold"
                      style={{ color: isDark ? "#ffffff" : "#171717" }}
                    >
                      Value: {formatCurrency(item.value, item.currency)}
                    </Text>
                  </View>
                </View>
              );
            }}
            ListEmptyComponent={() => (
              <View className="items-center justify-center py-12">
                <Text className="text-neutral-500 text-sm">
                  No active stock allocations.
                </Text>
              </View>
            )}
            contentContainerStyle={{ paddingBottom: 50 }}
            nestedScrollEnabled={true}
          />
        ) : (
          <ScrollView
            contentContainerStyle={{ paddingBottom: 50 }}
            showsVerticalScrollIndicator={false}
          >
            {/* Analytics Type Toggle */}
            <View
              className="flex-row justify-around border rounded-2xl p-1.5 mt-2 mb-6"
              style={{
                backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                borderColor: isDark ? "#27272a" : "#e5e5e5",
                shadowColor: "#000",
                shadowOffset: { width: 0, height: 1 },
                shadowOpacity: isDark ? 0.1 : 0.03,
                shadowRadius: 2,
                elevation: 1,
              }}
            >
              <Pressable
                className={`flex-1 py-2 rounded-xl items-center ${
                  chartMode === "VALUATION" ? "bg-positive" : ""
                }`}
                onPress={() => setChartMode("VALUATION")}
              >
                <Text
                  className="text-xs font-bold"
                  style={{
                    color: chartMode === "VALUATION" ? "#ffffff" : isDark ? "#a3a3a3" : "#737373",
                  }}
                >
                  Valuation Breakdown
                </Text>
              </Pressable>
              <Pressable
                className={`flex-1 py-2 rounded-xl items-center ${
                  chartMode === "DIVIDEND" ? "bg-amber-500" : ""
                }`}
                onPress={() => setChartMode("DIVIDEND")}
              >
                <Text
                  className="text-xs font-bold"
                  style={{
                    color: chartMode === "DIVIDEND" ? "#ffffff" : isDark ? "#a3a3a3" : "#737373",
                  }}
                >
                  Dividend Contribution
                </Text>
              </Pressable>
            </View>

            {/* Donut Charts Render */}
            {chartMode === "VALUATION" ? (
              <>
                {stockAllocItems.length > 0 ? (
                  <View className="flex-row gap-4">
                    <GridDonutChart
                      items={stockAllocItems}
                      title="Stock Weight"
                      subtitle={`${stockAllocItems.length} Assets`}
                      centerLabel="Stocks"
                      onPress={() =>
                        router.push({
                          pathname: "/profile/analysis",
                          params: { id, type: "stock" },
                        })
                      }
                    />
                    <GridDonutChart
                      items={sectorAllocItems}
                      title="Sector Weight"
                      subtitle={`${sectorAllocItems.length} Sectors`}
                      centerLabel="Sectors"
                      onPress={() =>
                        router.push({
                          pathname: "/profile/analysis",
                          params: { id, type: "sector" },
                        })
                      }
                    />
                  </View>
                ) : (
                  <View className="items-center justify-center py-12">
                    <Text className="text-neutral-500 text-sm">
                      No stock allocations found.
                    </Text>
                  </View>
                )}
              </>
            ) : (
              <>
                {dividendContribItems.length > 0 ? (
                  <View className="flex-row justify-center">
                    <GridDonutChart
                      items={dividendContribItems}
                      title="Dividend Yield"
                      subtitle={`${dividendContribItems.length} Contributors`}
                      centerLabel="Dividends"
                      onPress={() =>
                        router.push({
                          pathname: "/profile/analysis",
                          params: { id, type: "dividend" },
                        })
                      }
                    />
                  </View>
                ) : (
                  <View className="items-center justify-center py-12">
                    <Text className="text-neutral-500 text-sm">
                      No dividend contributions found.
                    </Text>
                  </View>
                )}
              </>
            )}
          </ScrollView>
        )}
      </SafeAreaView>
    </View>
  );
}
