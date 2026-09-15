// TaskCompletion 数据模型
// 完成打卡记录：用于计算连续完成天数

class TaskCompletion {
  final int? id;
  final int taskId;
  final String completionDate; // YYYY-MM-DD
  final String completedAt; // ISO 时间戳

  TaskCompletion({
    this.id,
    required this.taskId,
    required this.completionDate,
    required this.completedAt,
  });

  factory TaskCompletion.fromMap(Map<String, dynamic> map) {
    return TaskCompletion(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      completionDate: map['completion_date'] as String,
      completedAt: map['completed_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'completion_date': completionDate,
      'completed_at': completedAt,
    };
  }

  @override
  String toString() =>
      'TaskCompletion(id: $id, taskId: $taskId, date: $completionDate)';
}
