# StockTracker 📈

A premium, interactive wealth and dividend tracker application built with a modern **Python (FastAPI) Backend** and a high-performance **Dart / Flutter Desktop Frontend**.

---

## 🌟 Features

* **Dual Investment Profiles**: Track both Stock (`TFSA`) and Dividend (`RRSP`) portfolios with support for over 30+ holdings per profile.
* **Premium Organic Design**: Built with a responsive glowing background that tracks and responds to mouse hover coordinates dynamically.
* **3D Elliptical Pie Charts**: High-fidelity elliptical 3D pie charts featuring exploded slice separations, drop shadows, and premium light gradients.
* **Interactive Timeline Graphs**: 120Hz snapping line charts with crosshairs tracking value and dividend projections over time.
* **Consolidated Unified View**: Merged Python SQL backend logic with a Dart/Flutter frontend to replace legacy React Native setups.

---

## 🏗️ Architecture & Folder Structure

```
StockTracker/
├── frontend/             # Dart & Flutter desktop/mobile application
│   ├── lib/              # Application source code
│   │   ├── data/         # Models and API service providers
│   │   └── ui/           # Views, features, and core visual themes
│   └── pubspec.yaml      # Dart dependencies and assets configuration
│
└── wealth_tracker/       # Python FastAPI backend server
    ├── app/              # Database routers, models, and worker scripts
    ├── seed_db.py        # Database seeder (generates 35+ dummy profile holdings)
    └── requirements.txt  # Python requirements list
```

---

## 🚀 Getting Started

### 1. Backend Setup (`wealth_tracker`)

Make sure you have a running PostgreSQL database.

1. Navigate to the backend folder:
   ```bash
   cd wealth_tracker
   ```
2. Create and activate a virtual environment, then install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the database migrations & seed mock portfolios (TFSA & RRSP with 35 holdings each):
   ```bash
   python seed_db.py
   ```
4. Start the FastAPI development server:
   ```bash
   python run.py
   ```
   *The server runs locally at `http://localhost:8000`.*

---

### 2. Frontend Setup (`frontend`)

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) for your OS.
2. Navigate to the frontend folder:
   ```bash
   cd frontend
   ```
3. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
4. Run static analysis to verify lint rules:
   ```bash
   dart analyze
   ```
5. Run the application locally in desktop debug mode:
   ```bash
   flutter run -d macos
   ```
6. Build a release binary for distribution:
   ```bash
   flutter build macos
   ```

---

## 🛠️ Technology Stack

* **Frontend**: Dart, Flutter (impeller-enabled rendering, custom canvas decorators, Provider state management, GoRouter routing).
* **Backend**: Python 3, FastAPI, SQLAlchemy ORM, PostgreSQL database.
