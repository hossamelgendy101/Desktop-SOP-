# ProPOS - Complete Offline Point of Sale System

A production-ready, fully offline POS system built with Flutter Desktop for supermarkets, grocery stores, pharmacies, retail shops, and restaurants.

## Features

- **100% Offline** - No internet connection required
- **Multi-Role** - Admin, Manager, Cashier with permissions
- **Fast POS** - Barcode scanning, quick search, keyboard shortcuts
- **Inventory** - Multi-warehouse, stock alerts, expiry tracking
- **Customers** - Loyalty points, credit, balance tracking
- **Suppliers** - Purchase orders, payments, history
- **Reports** - Sales, profit, inventory, tax reports with charts
- **Printing** - Thermal ESC/POS & A4 PDF invoices
- **Backup** - Auto & manual backup/restore
- **RTL Support** - Full Arabic/English support
- **Dark Mode** - Material 3 dynamic theming

## Tech Stack

- Flutter 3.x (Desktop: Windows, macOS, Linux)
- SQLite (sqflite_common_ffi)
- BLoC State Management
- Clean Architecture / Repository Pattern

## Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux

# 3. Build release
flutter build windows
```

## Default Login

- **Username:** `admin`
- **Password:** `admin123`

## Project Structure

```
lib/
├── core/           # Constants, theme, extensions, errors
├── data/           # Models, repositories, database
├── domain/         # Entities, repository interfaces
├── presentation/   # BLoCs, screens, widgets
└── services/       # Print, backup, barcode, locale
```

## Database

SQLite database auto-created on first run. All data is encrypted at rest for sensitive fields.

## License

MIT License - Commercial use permitted.
