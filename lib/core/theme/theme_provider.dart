// 主题状态管理
// 用 Provider 管理主题风格和模式，用 SharedPreferences 持久化

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'theme_colors.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeStyle _style = ThemeStyle.minimal; // 极简/治愈
  ThemeMode _mode = ThemeMode.system; // 浅色/深色/跟随系统

  ThemeStyle get style => _style;
  ThemeMode get mode => _mode;

  /// 初始化：从 SharedPreferences 读取上次的选择
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final styleIndex = prefs.getInt(AppConstants.keyThemeStyle);
    final modeIndex = prefs.getInt(AppConstants.keyThemeMode);

    if (styleIndex != null) {
      _style = ThemeStyle.values[styleIndex];
    }
    if (modeIndex != null) {
      _mode = ThemeMode.values[modeIndex];
    }
    notifyListeners();
  }

  /// 切换主题风格（极简/治愈）
  Future<void> setStyle(ThemeStyle style) async {
    if (_style == style) return;
    _style = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeStyle, style.index);
  }

  /// 切换主题模式（浅色/深色/跟随系统）
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeMode, mode.index);
  }

  /// 获取当前 ThemeData（根据风格 + 模式）
  ThemeData get currentTheme {
    final brightness = _mode == ThemeMode.dark
        ? Brightness.dark
        : (_mode == ThemeMode.light ? Brightness.light : Brightness.light);
    return AppTheme.getTheme(_style, brightness);
  }
}
