import React, { useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  SafeAreaView,
  ScrollView,
  Text,
  TextInput,
  View,
} from "react-native";
import { useRouter } from "expo-router";

import { useAppTheme } from "@/context/ThemeContext";
import { apiService } from "@/services/api";

const BROKERS = ["Questrade", "Wealthsimple", "RBC Direct Investing", "Other"];

export default function ImportScreen() {
  const router = useRouter();
  const { isDark } = useAppTheme();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // Form State
  const [ticker, setTicker] = useState("");
  const [profileName, setProfileName] = useState("TFSA"); // TFSA or RRSP
  const [quantity, setQuantity] = useState("");
  const [pricePerShare, setPricePerShare] = useState("");
  const [brokerage, setBrokerage] = useState("Questrade");
  const [fxRate, setFxRate] = useState("1.0000");
  const [purchaseDate, setPurchaseDate] = useState("2026-07-16");

  const handleSubmit = async () => {
    setError("");
    if (!ticker.trim()) {
      setError("Ticker symbol/Share name is required.");
      return;
    }
    const q = parseFloat(quantity);
    const p = parseFloat(pricePerShare);
    if (isNaN(q) || q <= 0) {
      setError("Share quantity must be a positive number.");
      return;
    }
    if (isNaN(p) || p <= 0) {
      setError("Purchase price must be a positive number.");
      return;
    }
    const fx = parseFloat(fxRate);
    if (isNaN(fx) || fx <= 0) {
      setError("FX rate must be a positive number.");
      return;
    }
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(purchaseDate)) {
      setError("Date must be in YYYY-MM-DD format.");
      return;
    }

    setLoading(true);
    try {
      const payload = {
        ticker: ticker.toUpperCase().trim(),
        transactionType: "BUY",
        quantity: q,
        pricePerShare: p,
        brokerage,
        fxRate: fx,
        purchaseDate,
        profileName,
      };

      await apiService.importPortfolio(payload);
      console.log("[Import] Portfolio import submitted successfully.");
      router.replace("/dashboard");
    } catch (err: any) {
      setError("Failed to register asset. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <View
      className="flex-1"
      style={{ backgroundColor: isDark ? "#121212" : "#f5f5f5" }}
    >
      <SafeAreaView style={{ flex: 1, paddingHorizontal: 16 }}>
        {/* Header Bar */}
        <View className="flex-row items-center mt-6 mb-6">
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
              Import Asset
            </Text>
            <Text
              className="text-xs"
              style={{ color: isDark ? "#a3a3a3" : "#737373" }}
            >
              Fill in details to add a stock position
            </Text>
          </View>
        </View>

        {/* Scrollable Form container */}
        <ScrollView
          contentContainerStyle={{ paddingBottom: 40 }}
          className="flex-1"
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View
            className="border p-6 rounded-3xl mb-6"
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
            {error ? (
              <View className="bg-negative/10 border border-negative/20 px-4 py-2.5 rounded-xl mb-6">
                <Text className="text-negative text-xs font-semibold">{error}</Text>
              </View>
            ) : null}

            {/* 1. Ticker / Share Name */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Ticker Symbol / Share Name
              </Text>
              <TextInput
                className="w-full border rounded-xl px-4 py-3 uppercase"
                style={{
                  backgroundColor: isDark ? "#171717" : "#fafafa",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                  color: isDark ? "#ffffff" : "#171717",
                }}
                placeholder="e.g. AAPL, XIU, BHP"
                placeholderTextColor={isDark ? "#555" : "#999"}
                value={ticker}
                onChangeText={setTicker}
                autoCorrect={false}
                autoCapitalize="characters"
              />
            </View>

            {/* 2. Investment Profile Selection */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Investment Profile (Account)
              </Text>
              <View className="flex-row gap-3">
                {["TFSA", "RRSP"].map((type) => (
                  <Pressable
                    key={type}
                    className="flex-1 py-3 rounded-xl border items-center"
                    style={{
                      backgroundColor: profileName === type ? "rgba(76, 175, 80, 0.1)" : isDark ? "#171717" : "#fafafa",
                      borderColor: profileName === type ? "#4CAF50" : isDark ? "#27272a" : "#e5e5e5",
                    }}
                    onPress={() => setProfileName(type)}
                  >
                    <Text
                      className="font-semibold text-sm"
                      style={{
                        color: profileName === type ? "#4CAF50" : isDark ? "#a3a3a3" : "#737373",
                      }}
                    >
                      {type}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            {/* 3. Transaction Type */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Transaction Type
              </Text>
              <View
                className="w-full border rounded-xl px-4 py-3 opacity-60"
                style={{
                  backgroundColor: isDark ? "#171717" : "#fafafa",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                }}
              >
                <Text
                  className="font-bold"
                  style={{ color: isDark ? "#ffffff" : "#171717" }}
                >
                  BUY
                </Text>
              </View>
            </View>

            {/* 4. Share Quantity */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Share Quantity (Amount)
              </Text>
              <TextInput
                className="w-full border rounded-xl px-4 py-3"
                style={{
                  backgroundColor: isDark ? "#171717" : "#fafafa",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                  color: isDark ? "#ffffff" : "#171717",
                }}
                placeholder="e.g. 10.5"
                placeholderTextColor={isDark ? "#555" : "#999"}
                keyboardType="numeric"
                value={quantity}
                onChangeText={setQuantity}
              />
            </View>

            {/* 5. Purchase Price per Share */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Purchase Price per Share (in local buying currency)
              </Text>
              <TextInput
                className="w-full border rounded-xl px-4 py-3"
                style={{
                  backgroundColor: isDark ? "#171717" : "#fafafa",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                  color: isDark ? "#ffffff" : "#171717",
                }}
                placeholder="e.g. 185.00"
                placeholderTextColor={isDark ? "#555" : "#999"}
                keyboardType="numeric"
                value={pricePerShare}
                onChangeText={setPricePerShare}
              />
            </View>

            {/* 6. Brokerage */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Brokerage Used
              </Text>
              <View className="flex-row flex-wrap gap-2">
                {BROKERS.map((broker) => (
                  <Pressable
                    key={broker}
                    className="px-3 py-2 rounded-xl border"
                    style={{
                      backgroundColor: brokerage === broker ? "rgba(76, 175, 80, 0.1)" : isDark ? "#171717" : "#fafafa",
                      borderColor: brokerage === broker ? "#4CAF50" : isDark ? "#27272a" : "#e5e5e5",
                    }}
                    onPress={() => setBrokerage(broker)}
                  >
                    <Text
                      className="text-xs font-medium"
                      style={{
                        color: brokerage === broker ? "#4CAF50" : isDark ? "#a3a3a3" : "#737373",
                      }}
                    >
                      {broker}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            {/* 7. Local FX Rate */}
            <View className="mb-5">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Local Transaction FX Rate
              </Text>
              <TextInput
                className="w-full border rounded-xl px-4 py-3"
                style={{
                  backgroundColor: isDark ? "#171717" : "#fafafa",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                  color: isDark ? "#ffffff" : "#171717",
                }}
                placeholder="e.g. 1.0000"
                placeholderTextColor={isDark ? "#555" : "#999"}
                keyboardType="numeric"
                value={fxRate}
                onChangeText={setFxRate}
              />
              <Text
                className="text-[10px] mt-1.5"
                style={{ color: isDark ? "#737373" : "#a3a3a3" }}
              >
                Relative exchange rate back to native base currency.
              </Text>
            </View>

            {/* 8. Purchase Date */}
            <View className="mb-6">
              <Text
                className="text-xs font-bold uppercase tracking-wider mb-2"
                style={{ color: isDark ? "#a3a3a3" : "#737373" }}
              >
                Purchase Date (YYYY-MM-DD)
              </Text>
              <TextInput
                className="w-full border rounded-xl px-4 py-3"
                style={{
                  backgroundColor: isDark ? "#171717" : "#fafafa",
                  borderColor: isDark ? "#27272a" : "#e5e5e5",
                  color: isDark ? "#ffffff" : "#171717",
                }}
                placeholder="YYYY-MM-DD"
                placeholderTextColor={isDark ? "#555" : "#999"}
                value={purchaseDate}
                onChangeText={setPurchaseDate}
              />
            </View>

            {/* Submit Button */}
            <Pressable
              className="w-full py-4.5 rounded-xl items-center justify-center active:opacity-90 bg-positive mt-4 shadow-lg shadow-positive/25"
              onPress={handleSubmit}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text className="text-white font-bold text-base">Submit Transaction</Text>
              )}
            </Pressable>
          </View>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}
