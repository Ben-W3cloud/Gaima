import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/chat_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/prepare_page.dart';
import 'providers/app_providers.dart';
import 'providers/settings_providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const GaimaApp(),
    ),
  );
}

class GaimaApp extends ConsumerWidget {
  const GaimaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Gaima',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (_) => const AppGate(),
        '/chat': (_) => const ChatPage(),
        '/prepare': (_) => const PreparePage(),
      },
    );
  }
}

/// Routes the user based on persisted onboarding state:
/// Onboarding (privacy disclosure) → Prepare (model download) → Chat.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acknowledged = ref.watch(onboardingAcknowledgedProvider);
    return acknowledged ? const PreparePage() : const OnboardingPage();
  }
}
