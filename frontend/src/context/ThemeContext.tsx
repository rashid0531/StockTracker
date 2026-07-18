import { useState, useEffect } from "react";

type ThemeMode = "light" | "dark";

let currentTheme: ThemeMode = "dark";
const themeListeners = new Set<(theme: ThemeMode) => void>();

export const getTheme = () => currentTheme;

export const setTheme = (theme: ThemeMode) => {
  currentTheme = theme;
  themeListeners.forEach((listener) => listener(theme));
};

export const useAppTheme = () => {
  const [theme, setThemeState] = useState<ThemeMode>(currentTheme);

  useEffect(() => {
    const listener = (newTheme: ThemeMode) => {
      setThemeState(newTheme);
    };
    themeListeners.add(listener);
    return () => {
      themeListeners.delete(listener);
    };
  }, []);

  const isDark = theme === "dark";

  return {
    theme,
    isDark,
    setTheme,
    toggleTheme: () => setTheme(theme === "dark" ? "light" : "dark"),
  };
};
