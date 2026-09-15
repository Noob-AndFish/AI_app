// 全局常量
// 放数据库名、版本号、存储键名等全局配置

class AppConstants {
  AppConstants._(); // 私有构造，禁止实例化

  // ===== 数据库 =====
  static const String dbName = 'riji.db';
  static const int dbVersion = 1;

  // ===== SharedPreferences 键名 =====
  static const String keyThemeMode = 'themeMode'; // 浅色/深色/跟随系统
  static const String keyThemeStyle = 'themeStyle'; // 极简/治愈
  static const String keyAppLockEnabled = 'appLockEnabled'; // 应用锁开关
}
