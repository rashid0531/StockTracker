import React, { useEffect, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  SafeAreaView,
  Text,
  View,
} from "react-native";
import { useRouter } from "expo-router";

import { useAppTheme } from "@/context/ThemeContext";
import { apiService, checkUsingMock } from "@/services/api";

const USER_ID = "d0e34cbb-5820-4e1b-b384-cb9ef3a1b80c";

export default function DashboardScreen() {
  const router = useRouter();
  const { isDark } = useAppTheme();
  const [profiles, setProfiles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [globalTotal, setGlobalTotal] = useState(0);
  const [globalDividend, setGlobalDividend] = useState(0);

  const fetchProfiles = async () => {
    try {
      setLoading(true);
      const data = await apiService.getProfiles(USER_ID);
      setProfiles(data);

      // Sum all profile values in CAD (assuming USD is converted by 1.35 for the global aggregate value)
      const total = data.reduce((acc, p) => {
        const val = p.total_value;
        if (p.currency === "USD") {
          return acc + val * 1.35; // Convert USD to CAD for the display total
        }
        return acc + val;
      }, 0);
      setGlobalTotal(total);

      // Sum all projected dividends in CAD
      const totalDiv = data.reduce((acc, p) => {
        const val = p.projected_dividend || 0;
        if (p.currency === "USD") {
          return acc + val * 1.35;
        }
        return acc + val;
      }, 0);
      setGlobalDividend(totalDiv);
    } catch (err) {
      console.error("[Dashboard] Error fetching profiles:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfiles();
  }, []);

  const formatCurrency = (val: number, currency: string) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: currency,
      minimumFractionDigits: 2,
    }).format(val);
  };

  return (
    <View
      className="flex-1"
      style={{ backgroundColor: isDark ? "#121212" : "#f5f5f5" }}
    >
      <SafeAreaView style={{ flex: 1, paddingHorizontal: 16 }}>
      {/* Header section */}
      <View className="flex-row justify-between items-center mt-6 mb-4">
        <View>
          <Text
            className="text-2xl font-bold tracking-tight"
            style={{ color: isDark ? "#ffffff" : "#171717" }}
          >
            Dashboard
          </Text>
          <Text
            className="text-xs"
            style={{ color: isDark ? "#a3a3a3" : "#737373" }}
          >
            Welcome back, Jane Doe
          </Text>
        </View>
        <Pressable
          className="bg-positive px-4 py-2.5 rounded-xl active:opacity-90 shadow-md shadow-positive/20"
          onPress={() => router.push("/import")}
        >
          <Text className="text-white text-xs font-semibold">Import Asset</Text>
        </Pressable>
      </View>

      {loading ? (
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator size="large" color="#4CAF50" />
        </View>
      ) : (
        <FlatList
          data={profiles}
          keyExtractor={(item) => item.id}
          ListHeaderComponent={() => (
            <>
              {/* Aggregate Global Total Header Card */}
              <View
                className="border p-6 rounded-3xl mb-6 relative overflow-hidden"
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
                {/* Decorative glow background element */}
                <View className="absolute -right-16 -top-16 w-36 h-36 bg-positive/10 rounded-full blur-2xl" />

                <Text
                  className="text-xs font-bold uppercase tracking-widest mb-1"
                  style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                >
                  Global Combined Balance
                </Text>
                <Text
                  className="text-3xl font-extrabold tracking-tight"
                  style={{ color: isDark ? "#ffffff" : "#171717" }}
                >
                  {formatCurrency(globalTotal, "CAD")}
                </Text>
                <Text
                  className="text-sm font-semibold mt-1"
                  style={{ color: isDark ? "#e5e5e5" : "#404040" }}
                >
                  Est. Annual Dividend: {formatCurrency(globalDividend, "CAD")}
                </Text>
                <Text className="text-positive text-[10px] mt-2 font-medium">
                  ★ Standard base conversion (USD → CAD @ 1.35)
                </Text>

                {checkUsingMock() && (
                  <View className="bg-amber-500/10 border border-amber-500/20 px-3 py-1.5 rounded-lg mt-4 flex-row items-center">
                    <Text className="text-amber-500 text-xs font-semibold">
                      Offline Mode: Showing rich mock simulation
                    </Text>
                  </View>
                )}
              </View>

              <Text
                className="text-xs font-bold uppercase tracking-widest mb-3 pl-1"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Asset Accounts & Ledgers
              </Text>
            </>
          )}
          renderItem={({ item }) => (
            <Pressable
              className="border p-5 rounded-2xl mb-4 active:opacity-90 flex-row justify-between items-center"
              style={{
                backgroundColor: isDark ? "#1e1e1e" : "#ffffff",
                borderColor: isDark ? "#27272a" : "#e5e5e5",
                shadowColor: "#000",
                shadowOffset: { width: 0, height: 2 },
                shadowOpacity: isDark ? 0.2 : 0.05,
                shadowRadius: 6,
                elevation: 2,
              }}
              onPress={() => router.push(`/profile/${item.id}`)}
            >
              <View className="flex-1 pr-4">
                <Text
                  className="text-lg font-bold"
                  style={{ color: isDark ? "#ffffff" : "#171717" }}
                >
                  {item.name}
                </Text>
                <Text
                  className="text-xs mt-1"
                  style={{ color: isDark ? "#a3a3a3" : "#737373" }}
                  numberOfLines={1}
                >
                  Brokers: {item.brokerages}
                </Text>
                <Text className="text-positive text-xs mt-1 font-semibold">
                  Est. Dividend: {formatCurrency(item.projected_dividend || 0, item.currency)}
                </Text>
              </View>
              <View className="items-end">
                <Text
                  className="text-base font-bold"
                  style={{ color: isDark ? "#ffffff" : "#171717" }}
                >
                  {formatCurrency(item.total_value, item.currency)}
                </Text>
                <View
                  className="border px-2 py-0.5 rounded-md mt-1.5"
                  style={{
                    backgroundColor: isDark ? "#171717" : "#fafafa",
                    borderColor: isDark ? "#27272a" : "#e5e5e5",
                  }}
                >
                  <Text className="text-positive text-[10px] font-bold">
                    {item.currency}
                  </Text>
                </View>
              </View>
            </Pressable>
          )}
          ListEmptyComponent={() => (
            <View className="items-center justify-center py-12">
              <Text className="text-neutral-500 text-sm">
                No profiles loaded yet.
              </Text>
            </View>
          )}
          refreshing={loading}
          onRefresh={fetchProfiles}
          contentContainerStyle={{ paddingBottom: 40 }}
        />
      )}
      </SafeAreaView>
    </View>
  );
}
