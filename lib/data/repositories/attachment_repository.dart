// Attachment Repository
// 附件的 CRUD

import '../database/database_helper.dart';
import '../models/attachment.dart';

class AttachmentRepository {
  final DatabaseHelper _dbHelper;

  AttachmentRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // 新建附件记录
  Future<int> create({
    required String ownerType,
    required int ownerId,
    required String filePath,
    required String fileType,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('attachments', {
      'owner_type': ownerType,
      'owner_id': ownerId,
      'file_path': filePath,
      'file_type': fileType,
      'created_at': now,
    });
  }

  // 查询某记录的所有附件
  Future<List<Attachment>> getForOwner(String ownerType, int ownerId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'attachments',
      where: 'owner_type = ? AND owner_id = ?',
      whereArgs: [ownerType, ownerId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Attachment.fromMap).toList();
  }

  // 删除附件记录
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  // 删除某记录的所有附件
  Future<int> deleteAllForOwner(String ownerType, int ownerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'attachments',
      where: 'owner_type = ? AND owner_id = ?',
      whereArgs: [ownerType, ownerId],
    );
  }
}
