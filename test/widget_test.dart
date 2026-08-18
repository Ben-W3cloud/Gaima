import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaima/main.dart';
import 'package:gaima/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots into the onboarding gate', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const GaimaApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The onboarding privacy disclosure should be visible on first launch.
    expect(find.text('Gaima'), findsOneWidget);
    expect(find.text('I understand these limits'), findsOneWidget);
  });
}
