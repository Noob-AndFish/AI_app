// TaskOccurrence 数据模型
// 任务实例：某天应该完成的任务（懒生成）

class TaskOccurrence {
  final int? id;
  final int taskId;
  final String date; // YYYY-MM-DD
  final int isCompleted; // 1=完成 0=未完成

  TaskOccurrence({
    this.id,
    required this.taskId,
    required this.date,
    this.isCompleted = 0,
  });

  factory TaskOccurrence.fromMap(Map<String, dynamic> map) {
    return TaskOccurrence(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      date: map['date'] as String,
      isCompleted: (map['is_completed'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'date': date,
      'is_completed': isCompleted,
    };
  }

  TaskOccurrence copyWith({
    int? id,
    int? taskId,
    String? date,
    int? isCompleted,
  }) {
    return TaskOccurrence(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get completed => isCompleted == 1;

  @override
  String toString() => 'TaskOccurrence(id: $id, taskId: $taskId, date: $date)';
}
