// Tag 数据模型
// 标签：备忘录和日记共用

import 'dart:convert';

class Tag {
  final int? id;
  final String name;
  final String? color; // #RRGGBB 格式
  final String createdAt;

  Tag({
    this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  // 从数据库行构造
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  // 转为数据库行
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt,
    };
  }

  // 复制并修改
  Tag copyWith({
    int? id,
    String? name,
    String? color,
    String? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Tag(id: $id, name: $name, color: $color)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
