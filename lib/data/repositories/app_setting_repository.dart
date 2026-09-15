// AppSetting Repository
// 读写 app_settings 表的键值对
// 用于存应用级设置（如 PIN 哈希、备份版本号等）

import '../database/database_helper.dart';

class AppSettingRepository {
  final DatabaseHelper _dbHelper;

  AppSettingRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // 读取一个设置值（不存在返回 null）
  Future<String?> get(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // 写入一个设置值（不存在则插入，存在则更新）
  Future<void> set(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 删除一个设置值
  Future<void> remove(String key) async {
    final db = await _dbHelper.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  // 读取所有设置
  Future<Map<String, String>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('app_settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  // 清空所有设置
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('app_settings');
  }
}
