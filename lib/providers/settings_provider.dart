import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool oledDarkMode;
  final bool disableLiquidGlassBar;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.oledDarkMode = false,
    this.disableLiquidGlassBar = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? oledDarkMode,
    bool? disableLiquidGlassBar,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      oledDarkMode: oledDarkMode ?? this.oledDarkMode,
      disableLiquidGlassBar:
          disableLiquidGlassBar ?? this.disableLiquidGlassBar,
    );
  }
}

const _themeModeKey = 'settings_theme_mode';
const _oledDarkModeKey = 'settings_oled_dark_mode';
const _disableLiquidGlassBarKey = 'settings_disable_liquid_glass_bar';

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
    final disableLiquidGlassBar =
        prefs.getBool(_disableLiquidGlassBarKey) ?? true;
    state = AppSettings(
      themeMode: themeMode,
      oledDarkMode: oledThemeEnabled,
      disableLiquidGlassBar: disableLiquidGlassBar,
    );
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

  Future<void> setDisableLiquidGlassBar(bool disabled) async {
    state = state.copyWith(disableLiquidGlassBar: disabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disableLiquidGlassBarKey, disabled);
  }
}
