// Journal Repository
// 日记的 CRUD + 按日期排序

import '../database/database_helper.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  final DatabaseHelper _dbHelper;

  JournalRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // 新建日记
  Future<int> create({
    String? title,
    String? content,
    String? mood,
    String? weather,
    required String entryDate,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('journal_entries', {
      'title': title,
      'content': content,
      'mood': mood,
      'weather': weather,
      'entry_date': entryDate,
      'is_favorite': 0,
      'is_locked': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  // 按 id 查询
  Future<JournalEntry?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('journal_entries',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return JournalEntry.fromMap(rows.first);
  }

  // 按日期查询（一天只有一篇）
  Future<JournalEntry?> getByDate(String entryDate) async {
    final db = await _dbHelper.database;
    final rows = await db.query('journal_entries',
        where: 'entry_date = ?', whereArgs: [entryDate], limit: 1);
    if (rows.isEmpty) return null;
    return JournalEntry.fromMap(rows.first);
  }

  // 获取所有日记（按日期降序）
  Future<List<JournalEntry>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('journal_entries',
        orderBy: 'entry_date DESC, updated_at DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  // 获取收藏的日记
  Future<List<JournalEntry>> getFavorites() async {
    final db = await _dbHelper.database;
    final rows = await db.query('journal_entries',
        where: 'is_favorite = 1',
        orderBy: 'entry_date DESC, updated_at DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  // 更新
  Future<int> update(JournalEntry entry) async {
    final db = await _dbHelper.database;
    final updated = entry.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    return await db.update('journal_entries', updated.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  // 删除
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('journal_entries',
        where: 'id = ?', whereArgs: [id]);
  }

  // 切换收藏
  Future<void> toggleFavorite(int id, bool currentFavorite) async {
    final db = await _dbHelper.database;
    await db.update('journal_entries',
        {'is_favorite': currentFavorite ? 0 : 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // 切换隐私锁
  Future<void> toggleLocked(int id, bool currentLocked) async {
    final db = await _dbHelper.database;
    await db.update('journal_entries',
        {'is_locked': currentLocked ? 0 : 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // 总数
  Future<int> count() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT COUNT(*) as cnt FROM journal_entries');
    return rows.first['cnt'] as int;
  }

  // 获取所有日记日期（用于日历圆点标记）
  // 返回 {entry_date: is_favorite} 的 Map
  Future<Map<String, bool>> getAllDates() async {
    final db = await _dbHelper.database;
    final rows = await db.query('journal_entries',
        columns: ['entry_date', 'is_favorite']);
    return {
      for (final r in rows) r['entry_date'] as String: (r['is_favorite'] as int?) == 1,
    };
  }
}
