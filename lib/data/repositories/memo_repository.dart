// Memo Repository
// 备忘录的 CRUD + 置顶/归档切换 + 搜索 + 排序

import '../database/database_helper.dart';
import '../models/memo.dart';

// 排序方式
enum MemoSortBy {
  updatedAtDesc, // 按更新时间倒序（默认）
  updatedAtAsc, // 按更新时间正序
  createdAtDesc, // 按创建时间倒序
  titleAsc, // 按标题正序
}

class MemoRepository {
  final DatabaseHelper _dbHelper;

  MemoRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // 新建备忘录（返回新 id）
  Future<int> create({
    String? title,
    String? content,
    String? color,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('memos', {
      'title': title,
      'content': content,
      'color': color,
      'is_pinned': 0,
      'is_archived': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  // 按 id 查询
  Future<Memo?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Memo.fromMap(rows.first);
  }

  // 查询所有（支持排序 + 是否包含归档）
  // 排序：置顶永远在最前，再按指定字段排
  Future<List<Memo>> getAll({
    MemoSortBy sortBy = MemoSortBy.updatedAtDesc,
    bool includeArchived = false,
  }) async {
    final db = await _dbHelper.database;
    String where = '';
    if (!includeArchived) {
      where = 'is_archived = 0';
    }

    // 置顶在最前（is_pinned DESC），再按指定字段排
    String secondaryOrder;
    switch (sortBy) {
      case MemoSortBy.updatedAtDesc:
        secondaryOrder = 'updated_at DESC';
        break;
      case MemoSortBy.updatedAtAsc:
        secondaryOrder = 'updated_at ASC';
        break;
      case MemoSortBy.createdAtDesc:
        secondaryOrder = 'created_at DESC';
        break;
      case MemoSortBy.titleAsc:
        secondaryOrder = 'title ASC';
        break;
    }

    final rows = await db.query(
      'memos',
      where: where.isEmpty ? null : where,
      orderBy: 'is_pinned DESC, $secondaryOrder',
    );
    return rows.map(Memo.fromMap).toList();
  }

  // 模糊搜索（标题 + 正文）
  Future<List<Memo>> search(String keyword) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'memos',
      where: '(title LIKE ? OR content LIKE ?) AND is_archived = 0',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return rows.map(Memo.fromMap).toList();
  }

  // 更新备忘录
  Future<int> update(Memo memo) async {
    final db = await _dbHelper.database;
    final updated = memo.copyWith(updatedAt: DateTime.now().toIso8601String());
    return await db.update(
      'memos',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  // 设置置顶状态
  Future<int> setPinned(int id, bool pinned) async {
    final db = await _dbHelper.database;
    return await db.update(
      'memos',
      {
        'is_pinned': pinned ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 设置归档状态
  Future<int> setArchived(int id, bool archived) async {
    final db = await _dbHelper.database;
    return await db.update(
      'memos',
      {
        'is_archived': archived ? 1 : 0,
        'is_pinned': 0, // 归档时自动取消置顶
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 设置颜色标记
  Future<int> setColor(int id, String? color) async {
    final db = await _dbHelper.database;
    return await db.update(
      'memos',
      {
        'color': color,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除备忘录（关联表会因 ON DELETE CASCADE 自动清理）
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('memos', where: 'id = ?', whereArgs: [id]);
  }

  // 统计数量
  Future<int> count({bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final where = includeArchived ? null : 'is_archived = 0';
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM memos${where != null ? ' WHERE $where' : ''}',
    );
    return rows.first['cnt'] as int;
  }

  // 获取已归档列表
  Future<List<Memo>> getArchived({
    MemoSortBy sortBy = MemoSortBy.updatedAtDesc,
  }) async {
    final db = await _dbHelper.database;
    String secondaryOrder;
    switch (sortBy) {
      case MemoSortBy.updatedAtDesc:
        secondaryOrder = 'updated_at DESC';
        break;
      case MemoSortBy.updatedAtAsc:
        secondaryOrder = 'updated_at ASC';
        break;
      case MemoSortBy.createdAtDesc:
        secondaryOrder = 'created_at DESC';
        break;
      case MemoSortBy.titleAsc:
        secondaryOrder = 'title ASC';
        break;
    }
    final rows = await db.query(
      'memos',
      where: 'is_archived = 1',
      orderBy: secondaryOrder,
    );
    return rows.map(Memo.fromMap).toList();
  }
}
