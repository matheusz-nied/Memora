import 'package:flutter_test/flutter_test.dart';
import 'package:memora/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MemoraApp());

    expect(find.text('Memora'), findsOneWidget);
  });
}
