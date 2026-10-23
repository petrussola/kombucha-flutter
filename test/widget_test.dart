import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kombucha_app/pages/calculator_page.dart';

void main() {
  testWidgets('calculator updates when water amount changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CalculatorPage())),
    );

    expect(find.text('1.0 litre of water'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(300, 0));
    await tester.pump();
    expect(find.text('1.0 litre of water'), findsNothing);
  });
}
