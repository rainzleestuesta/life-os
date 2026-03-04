import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:life_flow/core/constants.dart';

/// Manages theme mode (light / dark / system) and persists to Hive.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final box = Hive.box(AppConstants.settingsBox);
    final stored = box.get('themeMode', defaultValue: 'light') as String;
    return _fromString(stored);
  }

  void toggle() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    Hive.box(AppConstants.settingsBox).put('themeMode', _toString(next));
  }

  void setMode(ThemeMode mode) {
    state = mode;
    Hive.box(AppConstants.settingsBox).put('themeMode', _toString(mode));
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
