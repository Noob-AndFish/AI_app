// Task Repository
// 任务的 CRUD + 重复规则引擎 + 懒生成实例 + 打卡

import '../database/database_helper.dart';
import '../models/task.dart';
import '../models/task_occurrence.dart';
import '../models/task_completion.dart';
import '../../shared/services/notification_service.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper;

  TaskRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // ===== Task CRUD =====

  Future<int> create({
    required String name,
    String? description,
    int priority = 3,
    RepeatRule? repeatRule,
    required String startDate,
    String? endDate,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('tasks', {
      'name': name,
      'description': description,
      'priority': priority,
      'repeat_rule': (repeatRule ?? RepeatRule.none()).toJson(),
      'start_date': startDate,
      'end_date': endDate,
      'is_active': 1,
      'created_at': now,
    });
  }

  Future<Task?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> getAllActive() async {
    final db = await _dbHelper.database;
    final rows = await db.query('tasks',
        where: 'is_active = 1', orderBy: 'priority DESC, created_at ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<int> update(Task task) async {
    final db = await _dbHelper.database;
    return await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    // CASCADE 会自动删 occurrences 和 completions
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setActive(int id, bool active) async {
    final db = await _dbHelper.database;
    return await db.update('tasks', {'is_active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ===== 重复规则引擎 =====

  // 判断某任务在某日期是否应该有实例
  bool shouldOccurOn(Task task, DateTime date) {
    final start = DateTime.parse(task.startDate);
    if (date.isBefore(DateTime(start.year, start.month, start.day))) return false;
    if (task.endDate != null) {
      final end = DateTime.parse(task.endDate!);
      if (date.isAfter(DateTime(end.year, end.month, end.day))) return false;
    }

    final rule = task.repeatRule;
    switch (rule.type) {
      case RepeatType.none:
        // 不重复：只在 startDate 当天
        final s = DateTime.parse(task.startDate);
        return date.year == s.year && date.month == s.month && date.day == s.day;
      case RepeatType.daily:
        return true;
      case RepeatType.weekday:
        // 周一到周五（1=周一 ... 5=周五）
        return date.weekday >= 1 && date.weekday <= 5;
      case RepeatType.weekly:
        return rule.weekdays?.contains(date.weekday) ?? false;
      case RepeatType.monthly:
        // 每月同一天
        final s = DateTime.parse(task.startDate);
        return date.day == s.day;
      case RepeatType.custom:
        // 每 interval 天
        final s = DateTime.parse(task.startDate);
        final diff = date.difference(DateTime(s.year, s.month, s.day)).inDays;
        return diff >= 0 && diff % rule.interval == 0;
    }
  }

  // 懒生成某天的所有任务实例（如果还没生成）
  Future<void> generateOccurrencesForDate(String date) async {
    final db = await _dbHelper.database;
    final tasks = await getAllActive();
    final targetDate = DateTime.parse(date);

    for (final task in tasks) {
      if (!shouldOccurOn(task, targetDate)) continue;

      // 检查是否已生成（UNIQUE 约束防重）
      final existing = await db.query(
        'task_occurrences',
        where: 'task_id = ? AND date = ?',
        whereArgs: [task.id, date],
        limit: 1,
      );
      if (existing.isEmpty) {
        await db.insert('task_occurrences', {
          'task_id': task.id,
          'date': date,
          'is_completed': 0,
        });
      }
    }
  }

  // ===== TaskOccurrence =====

  // 获取某天的任务实例（自动懒生成）
  Future<List<TaskOccurrence>> getOccurrencesForDate(String date) async {
    await generateOccurrencesForDate(date);
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT o.* FROM task_occurrences o
      INNER JOIN tasks t ON t.id = o.task_id
      WHERE o.date = ? AND t.is_active = 1
      ORDER BY t.priority DESC, t.created_at ASC
    ''', [date]);
    return rows.map(TaskOccurrence.fromMap).toList();
  }

  // 获取过期未完成的任务实例
  Future<List<TaskOccurrence>> getOverdueOccurrences() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT o.* FROM task_occurrences o
      INNER JOIN tasks t ON t.id = o.task_id
      WHERE o.date < ? AND o.is_completed = 0 AND t.is_active = 1
      ORDER BY o.date ASC
    ''', [todayStr]);
    return rows.map(TaskOccurrence.fromMap).toList();
  }

  // 标记某天的任务为完成/未完成
  // 打卡记录的 completion_date 使用 occurrence.date（补打卡也算那天完成）
  Future<void> toggleCompletion(int occurrenceId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('task_occurrences',
        where: 'id = ?', whereArgs: [occurrenceId], limit: 1);
    if (rows.isEmpty) return;
    final occ = TaskOccurrence.fromMap(rows.first);
    final newCompleted = occ.completed ? 0 : 1;

    await db.update('task_occurrences', {'is_completed': newCompleted},
        where: 'id = ?', whereArgs: [occurrenceId]);

    // 同步打卡记录：用 occurrence.date 而不是今天
    if (newCompleted == 1) {
      final now = DateTime.now();
      // occ.date 格式为 YYYY-MM-DD
      final existing = await db.query('task_completions',
          where: 'task_id = ? AND completion_date = ?',
          whereArgs: [occ.taskId, occ.date],
          limit: 1);
      if (existing.isEmpty) {
        await db.insert('task_completions', {
          'task_id': occ.taskId,
          'completion_date': occ.date,
          'completed_at': now.toIso8601String(),
        });
      }
    } else {
      await db.delete('task_completions',
          where: 'task_id = ? AND completion_date = ?',
          whereArgs: [occ.taskId, occ.date]);
    }
  }

  // ===== 连续天数统计 =====

  // 计算某任务的连续完成天数（从今天往前数）
  Future<int> getStreak(int taskId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'task_completions',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'completion_date DESC',
    );
    if (rows.isEmpty) return 0;

    // 检查今天是否完成
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayCompleted = rows.any((r) => r['completion_date'] == todayStr);

    int streak = 0;
    DateTime cursor = todayCompleted ? today : today.subtract(const Duration(days: 1));

    final completedDates = rows.map((r) => r['completion_date'] as String).toSet();
    while (true) {
      final dateStr =
          '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      if (completedDates.contains(dateStr)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // 统计完成率（最近 N 天）
  Future<double> getCompletionRate(int taskId, {int days = 30}) async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 最近 N 天的完成次数
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM task_completions
      WHERE task_id = ? AND completion_date >= date(?, '-${days - 1} days')
    ''', [taskId, todayStr]);
    final completed = rows.first['cnt'] as int;

    return days > 0 ? completed / days : 0;
  }

  // ===== 任务提醒 =====

  // 设置任务提醒（取消旧的，安排新的）
  Future<void> setTaskReminder({
    required int taskId,
    required int hour,
    required int minute,
    required RepeatRule repeatRule,
  }) async {
    final db = await _dbHelper.database;

    // 取任务名（用于通知正文）
    final taskRows = await db.query('tasks',
        where: 'id = ?', whereArgs: [taskId], limit: 1);
    if (taskRows.isEmpty) return;
    final taskName = taskRows.first['name'] as String;

    // 1. 取消旧通知
    await NotificationService.instance.cancel(taskId);

    // 2. 计算提醒时间（今天 + hour:minute）
    final now = DateTime.now();
    final remindAt = DateTime(now.year, now.month, now.day, hour, minute);

    // 3. 更新/插入 reminders 表
    final existing = await db.query('reminders',
        where: 'owner_type = ? AND owner_id = ?',
        whereArgs: ['task', taskId],
        limit: 1);
    if (existing.isEmpty) {
      await db.insert('reminders', {
        'owner_type': 'task',
        'owner_id': taskId,
        'remind_at': remindAt.toIso8601String(),
        'is_enabled': 1,
      });
    } else {
      await db.update(
        'reminders',
        {
          'remind_at': remindAt.toIso8601String(),
          'is_enabled': 1,
        },
        where: 'owner_type = ? AND owner_id = ?',
        whereArgs: ['task', taskId],
      );
    }

    // 4. 安排新通知
    final repeatDaily = repeatRule.type != RepeatType.none;
    await NotificationService.instance.scheduleReminder(
      id: taskId,
      title: '任务提醒',
      body: taskName,
      scheduledDate: remindAt,
      repeatDaily: repeatDaily,
    );
  }

  // 取消任务提醒
  Future<void> clearTaskReminder(int taskId) async {
    final db = await _dbHelper.database;
    await NotificationService.instance.cancel(taskId);
    await db.delete('reminders',
        where: 'owner_type = ? AND owner_id = ?',
        whereArgs: ['task', taskId]);
  }

  // 获取任务提醒时间（返回 [hour, minute] 或 null）
  Future<List<int>?> getTaskReminder(int taskId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('reminders',
        where: 'owner_type = ? AND owner_id = ? AND is_enabled = 1',
        whereArgs: ['task', taskId],
        limit: 1);
    if (rows.isEmpty) return null;
    try {
      final dt = DateTime.parse(rows.first['remind_at'] as String);
      return [dt.hour, dt.minute];
    } catch (_) {
      return null;
    }
  }
}
