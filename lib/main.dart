// 主入口
// 初始化主题状态后启动 App

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/theme/theme_provider.dart';
import 'data/database/database_helper.dart';
import 'features/memo/memo_provider.dart';
import 'features/journal/journal_provider.dart';
import 'features/today/task_provider.dart';
import 'shared/services/notification_service.dart';

void main() async {
  // 确保 Flutter 绑定初始化（异步操作前必须调）
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 locale 数据（用于中文日期格式化）
  await initializeDateFormatting();

  // 初始化数据库（会触发建表）
  final db = await DatabaseHelper().database;
  await db.query('app_settings', limit: 1);

  // 初始化通知服务
  await NotificationService.instance.init();

  // 初始化主题 Provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => MemoProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const RijiApp(),
    ),
  );
}
