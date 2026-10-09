import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/main.dart';

void main() {
  testWidgets('renders the placeholder shell', (tester) async {
    await tester.pumpWidget(const TaxcyDriverApp());
    expect(find.textContaining('Taxcy Driver'), findsOneWidget);
  });
}
