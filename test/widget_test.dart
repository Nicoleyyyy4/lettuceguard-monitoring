import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/main.dart';

void main() {
  testWidgets('LettuceGuard app smoke test', (WidgetTester tester) async {
    // Build LettuceGuardApp and trigger a frame.
    await tester.pumpWidget(const LettuceGuardApp());

    // Verify that LettuceGuard title or splash is displayed.
    expect(find.text('LettuceGuard'), findsWidgets);
  });
}
