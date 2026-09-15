// Memo 数据模型
// 备忘录：标题、正文（Markdown）、颜色标记、置顶、归档

class Memo {
  final int? id;
  final String? title;
  final String? content;
  final String? color; // 颜色标记 #RRGGBB
  final int isPinned; // 置顶 0/1
  final int isArchived; // 归档 0/1
  final String createdAt;
  final String updatedAt;

  Memo({
    this.id,
    this.title,
    this.content,
    this.color,
    this.isPinned = 0,
    this.isArchived = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从数据库行构造
  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'] as int?,
      title: map['title'] as String?,
      content: map['content'] as String?,
      color: map['color'] as String?,
      isPinned: (map['is_pinned'] as int?) ?? 0,
      isArchived: (map['is_archived'] as int?) ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  // 转为数据库行
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // 复制并修改
  Memo copyWith({
    int? id,
    String? title,
    String? content,
    String? color,
    int? isPinned,
    int? isArchived,
    String? createdAt,
    String? updatedAt,
  }) {
    return Memo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 便捷判断
  bool get pinned => isPinned == 1;
  bool get archived => isArchived == 1;

  @override
  String toString() =>
      'Memo(id: $id, title: $title, pinned: $pinned, archived: $archived)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Memo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
