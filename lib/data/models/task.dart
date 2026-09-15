// Task 数据模型
// 任务定义：名称、描述、日期、优先级、重复规则

import 'dart:convert';

// 重复类型
enum RepeatType {
  none, // 不重复
  daily, // 每天
  weekday, // 工作日（周一到周五）
  weekly, // 每周
  monthly, // 每月
  custom, // 自定义间隔
}

// 重复规则
class RepeatRule {
  final RepeatType type;
  final int interval; // 自定义间隔天数（仅 custom 用）
  final List<int>? weekdays; // 每周的哪几天（1=周一 ... 7=周日，仅 weekly 用）

  const RepeatRule({
    required this.type,
    this.interval = 1,
    this.weekdays,
  });

  // 不重复
  factory RepeatRule.none() => const RepeatRule(type: RepeatType.none);
  // 每天
  factory RepeatRule.daily() => const RepeatRule(type: RepeatType.daily);
  // 工作日
  factory RepeatRule.weekday() => const RepeatRule(type: RepeatType.weekday);
  // 每周（指定星期几，1=周一）
  factory RepeatRule.weekly(List<int> weekdays) =>
      RepeatRule(type: RepeatType.weekly, weekdays: weekdays);
  // 每月
  factory RepeatRule.monthly() => const RepeatRule(type: RepeatType.monthly);
  // 自定义间隔
  factory RepeatRule.custom(int days) =>
      RepeatRule(type: RepeatType.custom, interval: days);

  // JSON 序列化
  String toJson() => jsonEncode({
        'type': type.name,
        'interval': interval,
        'weekdays': weekdays,
      });

  // JSON 反序列化
  factory RepeatRule.fromJson(String? json) {
    if (json == null) return RepeatRule.none();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return RepeatRule(
        type: RepeatType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => RepeatType.none,
        ),
        interval: (map['interval'] as int?) ?? 1,
        weekdays: (map['weekdays'] as List<dynamic>?)?.cast<int>(),
      );
    } catch (_) {
      return RepeatRule.none();
    }
  }
}

class Task {
  final int? id;
  final String name;
  final String? description;
  final int priority; // 1-5，数字越大优先级越高
  final RepeatRule repeatRule;
  final String startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD，可空
  final int isActive; // 1=启用 0=停用
  final String createdAt;

  Task({
    this.id,
    required this.name,
    this.description,
    this.priority = 3,
    this.repeatRule = const RepeatRule(type: RepeatType.none),
    required this.startDate,
    this.endDate,
    this.isActive = 1,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      priority: (map['priority'] as int?) ?? 3,
      repeatRule: RepeatRule.fromJson(map['repeat_rule'] as String?),
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String?,
      isActive: (map['is_active'] as int?) ?? 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priority': priority,
      'repeat_rule': repeatRule.toJson(),
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  Task copyWith({
    int? id,
    String? name,
    String? description,
    int? priority,
    RepeatRule? repeatRule,
    String? startDate,
    String? endDate,
    int? isActive,
    String? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      repeatRule: repeatRule ?? this.repeatRule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get active => isActive == 1;

  @override
  String toString() => 'Task(id: $id, name: $name)';
}
