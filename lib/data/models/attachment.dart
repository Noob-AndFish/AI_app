// Attachment 数据模型
// 附件：备忘录和日记共用

class Attachment {
  final int? id;
  final String ownerType; // 'memo' 或 'journal'
  final int ownerId;
  final String filePath; // 相对路径（相对 attachments 目录）
  final String fileType; // 'image' 或 'file'
  final String createdAt;

  Attachment({
    this.id,
    required this.ownerType,
    required this.ownerId,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as int?,
      ownerType: map['owner_type'] as String,
      ownerId: map['owner_id'] as int,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_type': ownerType,
      'owner_id': ownerId,
      'file_path': filePath,
      'file_type': fileType,
      'created_at': createdAt,
    };
  }
}
