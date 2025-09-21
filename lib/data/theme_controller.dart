import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeController {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static const String _boxName = 'rehabBox';
  static const String _key = 'themeMode';

  Future<void> loadFromHive() async {
    try {
      final box = Hive.box(_boxName);
      final String? saved = box.get(_key) as String?;
      if (saved == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else if (saved == 'light') {
        themeMode.value = ThemeMode.light;
      } else if (saved == 'system') {
        themeMode.value = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final box = Hive.box(_boxName);
      final map = {
        ThemeMode.light: 'light',
        ThemeMode.dark: 'dark',
        ThemeMode.system: 'system',
      };
      await box.put(_key, map[mode]);
    } catch (_) {}
  }
}


