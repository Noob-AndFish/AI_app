// Tag Repository
// 标签的 CRUD，备忘录和日记共用

import '../database/database_helper.dart';
import '../models/tag.dart';

class TagRepository {
  final DatabaseHelper _dbHelper;

  TagRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // 新建标签（返回新 id）
  Future<int> create(String name, {String? color}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('tags', {
      'name': name,
      'color': color,
      'created_at': now,
    });
  }

  // 按 id 查询
  Future<Tag?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  // 按名称查询（精确匹配，不区分大小写）
  Future<Tag?> getByName(String name) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tags',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  // 查询所有标签（按名称排序）
  Future<List<Tag>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('tags', orderBy: 'name ASC');
    return rows.map(Tag.fromMap).toList();
  }

  // 更新标签
  Future<int> update(Tag tag) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  // 删除标签（关联表会因 ON DELETE CASCADE 自动清理）
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // 模糊搜索标签
  Future<List<Tag>> search(String keyword) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tags',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'name ASC',
    );
    return rows.map(Tag.fromMap).toList();
  }

  // 查询某备忘录的标签
  Future<List<Tag>> getTagsForMemo(int memoId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN memo_tags mt ON mt.tag_id = t.id
      WHERE mt.memo_id = ?
      ORDER BY t.name ASC
    ''', [memoId]);
    return rows.map(Tag.fromMap).toList();
  }

  // 查询某日记的标签
  Future<List<Tag>> getTagsForJournal(int journalId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN journal_tags jt ON jt.tag_id = t.id
      WHERE jt.journal_id = ?
      ORDER BY t.name ASC
    ''', [journalId]);
    return rows.map(Tag.fromMap).toList();
  }

  // 给备忘录设置标签（替换式：先清空再插入）
  Future<void> setTagsForMemo(int memoId, List<int> tagIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('memo_tags', where: 'memo_id = ?', whereArgs: [memoId]);
      for (final tagId in tagIds) {
        await txn.insert('memo_tags', {'memo_id': memoId, 'tag_id': tagId});
      }
    });
  }

  // 给日记设置标签（替换式）
  Future<void> setTagsForJournal(int journalId, List<int> tagIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('journal_tags',
          where: 'journal_id = ?', whereArgs: [journalId]);
      for (final tagId in tagIds) {
        await txn.insert(
            'journal_tags', {'journal_id': journalId, 'tag_id': tagId});
      }
    });
  }
}
