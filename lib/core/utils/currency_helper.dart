import 'package:intl/intl.dart';

class CurrencyHelper {
  static const List<Map<String, String>> currencies = [
    {'code': 'LKR', 'symbol': 'Rs.', 'name': 'Sri Lankan Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AED', 'symbol': 'AED', 'name': 'UAE Dirham'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  ];

  static String getSymbol(String currencyCode) {
    final found = currencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'code': currencyCode, 'symbol': currencyCode, 'name': ''},
    );
    return found['symbol'] ?? currencyCode;
  }

  static String formatAmount(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol ${formatter.format(amount)}';
  }
}
