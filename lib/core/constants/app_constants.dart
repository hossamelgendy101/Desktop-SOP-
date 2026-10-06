class AppConstants {
  static const String appName = 'ProPOS';
  static const String appVersion = '1.0.0';
  static const String databaseName = 'pos_system.db';

  static const List<String> roles = ['admin', 'manager', 'cashier'];
  static const List<String> paymentMethods = ['cash', 'card', 'wallet', 'mixed'];
  static const List<String> expenseFrequencies = ['daily', 'weekly', 'monthly', 'yearly'];

  static const double defaultVatRate = 0.15;
  static const int lowStockThreshold = 10;

  static const Map<String, String> languages = {
    'en': 'English',
    'ar': 'العربية',
  };
}
