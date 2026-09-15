// JournalEntry 数据模型
// 日记：标题、正文、心情、天气、日期、收藏、隐私锁

class JournalEntry {
  final int? id;
  final String? title;
  final String? content;
  final String? mood; // 心情 emoji（😊 😌 😐 😔 😢）
  final String? weather; // 天气（晴/阴/雨/雪/云）
  final String entryDate; // YYYY-MM-DD
  final int isFavorite; // 1=收藏 0=普通
  final int isLocked; // 1=加锁 0=普通
  final String createdAt;
  final String updatedAt;

  JournalEntry({
    this.id,
    this.title,
    this.content,
    this.mood,
    this.weather,
    required this.entryDate,
    this.isFavorite = 0,
    this.isLocked = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      title: map['title'] as String?,
      content: map['content'] as String?,
      mood: map['mood'] as String?,
      weather: map['weather'] as String?,
      entryDate: map['entry_date'] as String,
      isFavorite: (map['is_favorite'] as int?) ?? 0,
      isLocked: (map['is_locked'] as int?) ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mood': mood,
      'weather': weather,
      'entry_date': entryDate,
      'is_favorite': isFavorite,
      'is_locked': isLocked,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  JournalEntry copyWith({
    int? id,
    String? title,
    String? content,
    String? mood,
    String? weather,
    String? entryDate,
    int? isFavorite,
    int? isLocked,
    String? createdAt,
    String? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      entryDate: entryDate ?? this.entryDate,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get favorite => isFavorite == 1;
  bool get locked => isLocked == 1;

  @override
  String toString() => 'JournalEntry(id: $id, date: $entryDate, title: $title)';
}
