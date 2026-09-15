// MaterialApp 配置
// 集成主题、路由

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'router/app_router.dart';

class RijiApp extends StatelessWidget {
  const RijiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: '日迹',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      darkTheme: themeProvider.currentTheme,
      themeMode: themeProvider.mode,
      routerConfig: appRouter,
    );
  }
}
