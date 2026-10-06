import 'dart:math';

class InvoiceNumberGenerator {
  /// Generates a random yet professional invoice number like INV-74921
  static String generateRandom({String prefix = 'INV'}) {
    final random = Random();
    final number = 10000 + random.nextInt(90000); // 5 digit random number
    return '$prefix-$number';
  }

  /// Generates a timestamp-based sequential code like INV-202610-042
  static String generateTimestampBased({String prefix = 'INV'}) {
    final now = DateTime.now();
    final yearMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final randomPart = 100 + Random().nextInt(900);
    return '$prefix-$yearMonth-$randomPart';
  }
}
