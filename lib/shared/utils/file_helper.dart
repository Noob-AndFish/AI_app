// 文件工具
// 处理图片复制到 attachments 目录

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileHelper {
  FileHelper._();

  // 获取 attachments 目录的绝对路径
  static Future<Directory> getAttachmentsDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // 把源文件复制到 attachments 目录，返回相对路径
  // 文件名用时间戳+扩展名，避免重名
  static Future<String> copyToAttachments(String sourcePath) async {
    final dir = await getAttachmentsDir();
    final ext = p.extension(sourcePath); // .jpg/.png
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(dir.path, fileName);
    await File(sourcePath).copy(destPath);
    return fileName; // 只返回文件名，相对 attachments 目录
  }

  // 把相对路径转成绝对路径（用于显示图片）
  static Future<String> getAbsolutePath(String relativePath) async {
    final dir = await getAttachmentsDir();
    return p.join(dir.path, relativePath);
  }

  // 删除 attachments 目录里的某个文件
  static Future<void> deleteFile(String relativePath) async {
    try {
      final dir = await getAttachmentsDir();
      final file = File(p.join(dir.path, relativePath));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 忽略删除失败
    }
  }
}
