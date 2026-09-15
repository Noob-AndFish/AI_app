// 主题配置
// 根据风格（极简/治愈）+ 模式（浅/深）生成 ThemeData

import 'package:flutter/material.dart';
import 'theme_colors.dart';

class AppTheme {
  AppTheme._();

  /// 极简模式 - 浅色
  static ThemeData get minimalLight => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: MinimalColors.lightPrimary,
          surface: MinimalColors.lightSurface,
          background: MinimalColors.lightBackground,
        ),
        scaffoldBackgroundColor: MinimalColors.lightBackground,
        dividerColor: MinimalColors.lightDivider,
        appBarTheme: const AppBarTheme(
          backgroundColor: MinimalColors.lightBackground,
          foregroundColor: MinimalColors.lightPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: MinimalColors.lightPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: MinimalColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 极简：小圆角
          ),
        ),
      );

  /// 极简模式 - 深色
  static ThemeData get minimalDark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: MinimalColors.darkPrimary,
          surface: MinimalColors.darkSurface,
          background: MinimalColors.darkBackground,
        ),
        scaffoldBackgroundColor: MinimalColors.darkBackground,
        dividerColor: MinimalColors.darkDivider,
        appBarTheme: const AppBarTheme(
          backgroundColor: MinimalColors.darkBackground,
          foregroundColor: MinimalColors.darkPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: MinimalColors.darkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: MinimalColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  /// 治愈模式 - 浅色
  static ThemeData get healingLight => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: HealingColors.lightPrimary,
          surface: HealingColors.lightSurface,
          background: HealingColors.lightBackground,
          secondary: HealingColors.lightAccent,
        ),
        scaffoldBackgroundColor: HealingColors.lightBackground,
        dividerColor: HealingColors.lightDivider,
        appBarTheme: const AppBarTheme(
          backgroundColor: HealingColors.lightBackground,
          foregroundColor: HealingColors.lightPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: HealingColors.lightPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: HealingColors.lightSurface,
          elevation: 2, // 治愈：轻微阴影
          shadowColor: HealingColors.lightDivider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 治愈：大圆角
          ),
        ),
      );

  /// 治愈模式 - 深色
  static ThemeData get healingDark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: HealingColors.darkPrimary,
          surface: HealingColors.darkSurface,
          background: HealingColors.darkBackground,
          secondary: HealingColors.darkAccent,
        ),
        scaffoldBackgroundColor: HealingColors.darkBackground,
        dividerColor: HealingColors.darkDivider,
        appBarTheme: const AppBarTheme(
          backgroundColor: HealingColors.darkBackground,
          foregroundColor: HealingColors.darkPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: HealingColors.darkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: HealingColors.darkSurface,
          elevation: 2,
          shadowColor: HealingColors.darkDivider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  /// 根据风格和模式获取主题
  static ThemeData getTheme(ThemeStyle style, Brightness brightness) {
    if (style == ThemeStyle.minimal) {
      return brightness == Brightness.light ? minimalLight : minimalDark;
    } else {
      return brightness == Brightness.light ? healingLight : healingDark;
    }
  }
}
