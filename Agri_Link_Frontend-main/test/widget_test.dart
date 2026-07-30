import 'package:flutter_test/flutter_test.dart';
import 'package:agrilink/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App launches without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgriLinkApp()));
    expect(find.byType(AgriLinkApp), findsOneWidget);
  });
}
