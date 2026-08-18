import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

const _kOnboardingKey = 'onboarding_acknowledged';
const _kThemeKey = 'theme_override';

/// Whether the first-launch privacy disclosure has been acknowledged.
final onboardingAcknowledgedProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_kOnboardingKey) ?? false;
});

/// Marks the onboarding disclosure acknowledged (persisted).
final acknowledgeOnboardingProvider =
    FutureProvider<void>((ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool(_kOnboardingKey, true);
  ref.read(onboardingAcknowledgedProvider.notifier).state = true;
});

/// Persistable theme override (default: follow system).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kThemeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_kThemeKey, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);