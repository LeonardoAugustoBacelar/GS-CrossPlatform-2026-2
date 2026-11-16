import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences_provider.dart';

/// Preferências globais do app, persistidas no aparelho.
@immutable
class AppSettings {
  const AppSettings({
    this.consentGiven = false,
    this.themeMode = ThemeMode.system,
    this.highContrast = false,
    this.textScale = 1.0,
  });

  final bool consentGiven;
  final ThemeMode themeMode;
  final bool highContrast;

  /// Multiplicador aplicado sobre o tamanho de fonte do sistema.
  final double textScale;

  AppSettings copyWith({
    bool? consentGiven,
    ThemeMode? themeMode,
    bool? highContrast,
    double? textScale,
  }) {
    return AppSettings(
      consentGiven: consentGiven ?? this.consentGiven,
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
    );
  }
}

class SettingsController extends Notifier<AppSettings> {
  static const _consentKey = 'settings.consent_given';
  static const _themeModeKey = 'settings.theme_mode';
  static const _highContrastKey = 'settings.high_contrast';
  static const _textScaleKey = 'settings.text_scale';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      consentGiven: prefs.getBool(_consentKey) ?? false,
      themeMode:
          ThemeMode.values.asNameMap()[prefs.getString(_themeModeKey)] ??
          ThemeMode.system,
      highContrast: prefs.getBool(_highContrastKey) ?? false,
      textScale: prefs.getDouble(_textScaleKey) ?? 1.0,
    );
  }

  Future<void> giveConsent() async {
    state = state.copyWith(consentGiven: true);
    await _prefs.setBool(_consentKey, true);
  }

  /// Retira o consentimento e apaga todos os dados guardados no aparelho.
  Future<void> revokeConsentAndDeleteData() async {
    await _prefs.clear();
    state = const AppSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    await _prefs.setBool(_highContrastKey, value);
  }

  Future<void> setTextScale(double value) async {
    state = state.copyWith(textScale: value);
    await _prefs.setDouble(_textScaleKey, value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
