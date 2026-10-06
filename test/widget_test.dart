import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_app/main.dart';

void main() {
  testWidgets('Invoice app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const InvoiceApp());
    expect(find.byType(InvoiceApp), findsOneWidget);
  });
}
