// 主题色板
// 极简模式：黑白灰为主
// 治愈模式：奶油白、浅杏、雾蓝、鼠尾草绿等柔和色

import 'package:flutter/material.dart';

/// 主题风格枚举
enum ThemeStyle {
  minimal, // 极简模式
  healing, // 治愈模式
}

/// 极简模式色板
class MinimalColors {
  // 浅色
  static const Color lightPrimary = Color(0xFF212121); // 近黑
  static const Color lightBackground = Color(0xFFFAFAFA); // 浅灰白
  static const Color lightSurface = Color(0xFFFFFFFF); // 纯白
  static const Color lightDivider = Color(0xFFE0E0E0); // 细线

  // 深色
  static const Color darkPrimary = Color(0xFFEEEEEE); // 近白
  static const Color darkBackground = Color(0xFF121212); // 近黑
  static const Color darkSurface = Color(0xFF1E1E1E); // 深灰
  static const Color darkDivider = Color(0xFF2C2C2C); // 深灰线
}

/// 治愈模式色板
class HealingColors {
  // 浅色
  static const Color lightPrimary = Color(0xFF6B7B6E); // 鼠尾草绿
  static const Color lightBackground = Color(0xFFFFF8F0); // 奶油白
  static const Color lightSurface = Color(0xFFFFFDF8); // 暖白
  static const Color lightAccent = Color(0xFFB8C5D6); // 雾蓝
  static const Color lightDivider = Color(0xFFE8DDD0); // 浅杏

  // 深色
  static const Color darkPrimary = Color(0xFFB8C5B0); // 柔和绿
  static const Color darkBackground = Color(0xFF2A2D2A); // 深绿灰
  static const Color darkSurface = Color(0xFF353A35); // 深鼠尾草
  static const Color darkAccent = Color(0xFF8FA0B5); // 深雾蓝
  static const Color darkDivider = Color(0xFF4A4F4A); // 深杏线
}
