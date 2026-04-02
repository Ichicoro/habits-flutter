import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool oledDarkMode;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.oledDarkMode = false,
  });

  AppSettings copyWith({ThemeMode? themeMode, bool? oledDarkMode}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      oledDarkMode: oledDarkMode ?? this.oledDarkMode,
    );
  }
}

const _themeModeKey = 'settings_theme_mode';
const _oledDarkModeKey = 'settings_oled_dark_mode';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeMode = switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final oledThemeEnabled = prefs.getBool(_oledDarkModeKey) ?? false;
    state = AppSettings(themeMode: themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setOledDarkMode(bool enabled) async {
    state = state.copyWith(oledDarkMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_oledDarkModeKey, enabled);
  }
}
