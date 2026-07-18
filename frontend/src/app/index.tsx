import React, { useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  SafeAreaView,
  Text,
  TextInput,
  View,
} from "react-native";
import { useRouter } from "expo-router";

import { apiService } from "@/services/api";
import { useAppTheme } from "@/context/ThemeContext";

export default function LoginScreen() {
  const router = useRouter();
  const { theme, isDark, setTheme } = useAppTheme();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async () => {
    setError("");
    if (!email || !password) {
      setError("Please fill in all fields.");
      return;
    }
    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setError("Please enter a valid email address.");
      return;
    }

    setLoading(true);
    try {
      const user = await apiService.login(email);
      console.log("[Login] Success, user ID:", user.id);
      // Navigate to dashboard
      router.replace("/dashboard");
    } catch (err: any) {
      setError("Authentication failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <View
      className="flex-1"
      style={{ backgroundColor: isDark ? "#0c0d0e" : "#ffffff" }}
    >
      <SafeAreaView style={{ flex: 1 }}>
        <View className="flex-1 justify-between px-8 py-8">
          {/* Brand Header */}
          <View className="items-center mt-12">
            <View className="w-20 h-20 bg-positive rounded-3xl items-center justify-center mb-6 shadow-xl shadow-positive/30">
              <Text className="text-white text-4xl font-black">W</Text>
            </View>
            <Text
              className="text-4xl font-extrabold tracking-tight"
              style={{ color: isDark ? "#ffffff" : "#0c0d0e" }}
            >
              Wealth Ledger
            </Text>
            <Text
              className="text-sm mt-2 font-medium"
              style={{ color: isDark ? "#888c94" : "#6c727f" }}
            >
              Production-Grade Asset Tracker
            </Text>
          </View>

          {/* Form Fields */}
          <View className="w-full" style={{ gap: 20 }}>
            <View>
              <Text
                className="text-[11px] font-bold uppercase tracking-widest mb-2.5 pl-1"
                style={{ color: isDark ? "#888c94" : "#6c727f" }}
              >
                Email Address
              </Text>
              <TextInput
                className="w-full border rounded-2xl px-5 py-4 text-base"
                style={{
                  backgroundColor: isDark ? "#16171a" : "#f3f4f6",
                  borderColor: isDark ? "#282a30" : "#e5e7eb",
                  color: isDark ? "#ffffff" : "#0c0d0e",
                }}
                placeholder="name@example.com"
                placeholderTextColor={isDark ? "#4b5260" : "#9ca3af"}
                keyboardType="email-address"
                autoCapitalize="none"
                value={email}
                onChangeText={setEmail}
              />
            </View>

            <View>
              <Text
                className="text-[11px] font-bold uppercase tracking-widest mb-2.5 pl-1"
                style={{ color: isDark ? "#888c94" : "#6c727f" }}
              >
                Password
              </Text>
              <TextInput
                className="w-full border rounded-2xl px-5 py-4 text-base"
                style={{
                  backgroundColor: isDark ? "#16171a" : "#f3f4f6",
                  borderColor: isDark ? "#282a30" : "#e5e7eb",
                  color: isDark ? "#ffffff" : "#0c0d0e",
                }}
                placeholder="••••••••"
                placeholderTextColor={isDark ? "#4b5260" : "#9ca3af"}
                secureTextEntry
                autoCapitalize="none"
                value={password}
                onChangeText={setPassword}
              />
            </View>

            {error ? (
              <Text className="text-negative text-xs font-bold mt-1 pl-1">
                {error}
              </Text>
            ) : null}

            {/* Sign In Button */}
            <Pressable
              className="w-full py-4.5 rounded-2xl items-center justify-center active:opacity-90 shadow-lg shadow-positive/25"
              style={{ backgroundColor: loading ? (isDark ? "#22252a" : "#e5e7eb") : "#4CAF50" }}
              onPress={handleLogin}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color={isDark ? "#888c94" : "#9ca3af"} />
              ) : (
                <Text className="text-white font-bold text-base tracking-wide">Sign In</Text>
              )}
            </Pressable>
          </View>

          {/* Theme Selector Toggle */}
          <View
            className="border-t flex-row justify-between items-center pt-6"
            style={{ borderTopColor: isDark ? "#1c1e22" : "#f3f4f6" }}
          >
            <Text
              className="text-xs font-bold uppercase tracking-wider"
              style={{ color: isDark ? "#525866" : "#9ca3af" }}
            >
              Theme Mode
            </Text>
            <View
              className="flex-row p-1 rounded-2xl border"
              style={{
                backgroundColor: isDark ? "#16171a" : "#f3f4f6",
                borderColor: isDark ? "#282a30" : "#e5e7eb",
              }}
            >
              <Pressable
                className="px-4 py-2.5 rounded-xl"
                style={{ backgroundColor: isDark ? "#282a30" : "transparent" }}
                onPress={() => setTheme("dark")}
              >
                <Text
                  className="text-xs font-extrabold tracking-wide"
                  style={{ color: isDark ? "#ffffff" : "#9ca3af" }}
                >
                  Dark
                </Text>
              </Pressable>
              <Pressable
                className="px-4 py-2.5 rounded-xl"
                style={{
                  backgroundColor: !isDark ? "#ffffff" : "transparent",
                  shadowColor: "#000",
                  shadowOffset: { width: 0, height: 1 },
                  shadowOpacity: !isDark ? 0.08 : 0,
                  shadowRadius: 2,
                  elevation: !isDark ? 1 : 0,
                }}
                onPress={() => setTheme("light")}
              >
                <Text
                  className="text-xs font-extrabold tracking-wide"
                  style={{ color: !isDark ? "#0c0d0e" : "#525866" }}
                >
                  Light
                </Text>
              </Pressable>
            </View>
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
}
