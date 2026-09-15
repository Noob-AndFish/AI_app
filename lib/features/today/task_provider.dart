// TaskProvider
// 任务的状态管理：加载今日任务、切换完成、统计

import 'package:flutter/material.dart';
import '../../data/models/task.dart';
import '../../data/models/task_occurrence.dart';
import '../../data/repositories/task_repository.dart';

// 今日任务的展示单元：实例 + 任务定义 + 连续天数
class TodayTaskItem {
  final TaskOccurrence occurrence;
  final Task task;
  final int streak;

  const TodayTaskItem({
    required this.occurrence,
    required this.task,
    required this.streak,
  });

  bool get completed => occurrence.completed;
}

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo;

  List<TodayTaskItem> _todayItems = [];
  List<TodayTaskItem> get todayItems => _todayItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TaskProvider([TaskRepository? repo]) : _repo = repo ?? TaskRepository();

  // 加载今日任务（自动懒生成 + 组装详情）
  Future<void> loadToday() async {
    _isLoading = true;
    notifyListeners();

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // getOccurrencesForDate 内部会自动懒生成当天实例
    final occurrences = await _repo.getOccurrencesForDate(todayStr);

    final items = <TodayTaskItem>[];
    for (final occ in occurrences) {
      final task = await _repo.getById(occ.taskId);
      if (task == null) continue;
      final streak = await _repo.getStreak(task.id!);
      items.add(TodayTaskItem(
        occurrence: occ,
        task: task,
        streak: streak,
      ));
    }

    _todayItems = items;
    _isLoading = false;
    notifyListeners();
    // 顺带加载过期任务（用于今日页过期徽章）
    await loadOverdue();
  }

  // 切换某条任务的完成状态
  Future<void> toggleComplete(int occurrenceId) async {
    await _repo.toggleCompletion(occurrenceId);
    await loadToday();
    await loadOverdue();
  }

  // ===== 过期任务 =====
  List<TodayTaskItem> _overdueItems = [];
  List<TodayTaskItem> get overdueItems => _overdueItems;

  int get overdueCount => _overdueItems.length;

  // 加载过期未完成的任务（按日期升序，最旧的在前）
  Future<void> loadOverdue() async {
    final occurrences = await _repo.getOverdueOccurrences();
    final items = <TodayTaskItem>[];
    for (final occ in occurrences) {
      final task = await _repo.getById(occ.taskId);
      if (task == null) continue;
      final streak = await _repo.getStreak(task.id!);
      items.add(TodayTaskItem(
        occurrence: occ,
        task: task,
        streak: streak,
      ));
    }
    _overdueItems = items;
    notifyListeners();
  }

  // 切换过期任务的完成状态
  Future<void> toggleOverdueComplete(int occurrenceId) async {
    await _repo.toggleCompletion(occurrenceId);
    await loadOverdue();
    await loadToday();
  }

  // 新建任务
  Future<int> createTask({
    required String name,
    String? description,
    required int priority,
    required RepeatRule repeatRule,
    required String startDate,
    String? endDate,
    int? remindHour,
    int? remindMinute,
  }) async {
    final id = await _repo.create(
      name: name,
      description: description,
      priority: priority,
      repeatRule: repeatRule,
      startDate: startDate,
      endDate: endDate,
    );
    // 设置提醒（如果指定了时间）
    if (remindHour != null && remindMinute != null) {
      await _repo.setTaskReminder(
        taskId: id,
        hour: remindHour,
        minute: remindMinute,
        repeatRule: repeatRule,
      );
    }
    await loadToday();
    return id;
  }

  // 更新任务
  Future<void> updateTask(
    Task task, {
    int? remindHour,
    int? remindMinute,
  }) async {
    await _repo.update(task);
    // 更新提醒
    if (remindHour != null && remindMinute != null) {
      await _repo.setTaskReminder(
        taskId: task.id!,
        hour: remindHour,
        minute: remindMinute,
        repeatRule: task.repeatRule,
      );
    } else {
      // 没传提醒参数 = 不改提醒
    }
    await loadToday();
  }

  // 删除任务（CASCADE 会清掉实例和打卡 + 取消通知）
  Future<void> deleteTask(int id) async {
    await _repo.clearTaskReminder(id);
    await _repo.delete(id);
    await loadToday();
  }

  // 获取任务提醒时间（编辑时用）
  Future<List<int>?> getTaskReminder(int taskId) {
    return _repo.getTaskReminder(taskId);
  }

  // 清除任务提醒
  Future<void> clearTaskReminder(int taskId) async {
    await _repo.clearTaskReminder(taskId);
  }

  // ===== 统计 =====
  int get total => _todayItems.length;
  int get completedCount =>
      _todayItems.where((i) => i.completed).length;
  double get progress => total == 0 ? 0 : completedCount / total;
}
