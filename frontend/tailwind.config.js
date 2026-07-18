/** @type {import('tailwindcss').Config} */
module.exports = {
  // Match all files in the app and components directories
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        background: "#121212",
        card: "#1E1E1E",
        positive: "#4CAF50",
        negative: "#F44336",
        muted: "#9E9E9E",
      },
    },
  },
  plugins: [],
};
