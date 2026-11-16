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
    this.notificationsEnabled = false,
  });

  final bool consentGiven;
  final ThemeMode themeMode;
  final bool highContrast;

  /// Multiplicador aplicado sobre o tamanho de fonte do sistema.
  final double textScale;
  final bool notificationsEnabled;

  AppSettings copyWith({
    bool? consentGiven,
    ThemeMode? themeMode,
    bool? highContrast,
    double? textScale,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      consentGiven: consentGiven ?? this.consentGiven,
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsController extends Notifier<AppSettings> {
  static const _consentKey = 'settings.consent_given';
  static const _themeModeKey = 'settings.theme_mode';
  static const _highContrastKey = 'settings.high_contrast';
  static const _textScaleKey = 'settings.text_scale';
  static const _notificationsKey = 'settings.notifications';

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
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? false,
    );
  }

  Future<void> giveConsent() async {
    await _prefs.setBool(_consentKey, true);
    state = state.copyWith(consentGiven: true);
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

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs.setBool(_notificationsKey, value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
