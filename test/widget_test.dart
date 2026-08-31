import 'package:flutter_test/flutter_test.dart';
import 'package:ramadhan_flutter/main.dart';

void main() {
  testWidgets('RamadanApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RamadanApp());
    expect(find.byType(RamadanApp), findsOneWidget);
  });
}
