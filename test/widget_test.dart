import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_mobile/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App inicia com ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuminaApp()));
    expect(find.text('Lumina Library'), findsOneWidget);
  });
}
