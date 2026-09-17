// 日记导出服务
// Markdown / PDF 生成 + 落盘到应用文档目录 + 系统分享
// PDF 使用打包的 SimHei 中文字体（assets/fonts/SimHei.ttf），否则中文显示为方块

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../data/models/journal_entry.dart';

class JournalExportService {
  // 缓存中文字体，避免每次导出都读 asset
  pw.Font? _cjkFont;

  /// 单篇导出为 Markdown，返回文件路径
  Future<String> exportSingleMarkdown(JournalEntry entry) async {
    final md = _entryToMarkdown(entry);
    return _writeFile('diary_${entry.entryDate}.md', md);
  }

  /// 批量导出为 Markdown（按日期升序合并），返回文件路径
  Future<String> exportBatchMarkdown(List<JournalEntry> entries) async {
    final sorted = [...entries]
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
    final buf = StringBuffer()
      ..writeln('# 日记合集\n')
      ..writeln('共 ${sorted.length} 篇\n');
    for (final e in sorted) {
      buf.writeln(_entryToMarkdown(e));
      buf.writeln('\n---\n');
    }
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return _writeFile('diaries_$stamp.md', buf.toString());
  }

  /// 单篇导出为 PDF，返回文件路径
  Future<String> exportSinglePdf(JournalEntry entry) async {
    final font = await _loadCjkFont();
    final doc = pw.Document();
    doc.addPage(_buildPdfPage(entry, font));
    final bytes = await doc.save();
    return _writeBytesFile('diary_${entry.entryDate}.pdf', bytes);
  }

  /// 批量导出为 PDF（每篇一页），返回文件路径
  Future<String> exportBatchPdf(List<JournalEntry> entries) async {
    final font = await _loadCjkFont();
    final sorted = [...entries]
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
    final doc = pw.Document();
    for (final e in sorted) {
      doc.addPage(_buildPdfPage(e, font));
    }
    final bytes = await doc.save();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return _writeBytesFile('diaries_$stamp.pdf', bytes);
  }

  /// 调用系统分享
  Future<void> shareFile(String path, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject),
    );
  }

  // ============ 内部方法 ============

  Future<pw.Font> _loadCjkFont() async {
    if (_cjkFont != null) return _cjkFont!;
    final data = await rootBundle.load('assets/fonts/SimHei.ttf');
    _cjkFont = pw.Font.ttf(data);
    return _cjkFont!;
  }

  Future<String> _writeFile(String fileName, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'exports', fileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file.path;
  }

  Future<String> _writeBytesFile(String fileName, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'exports', fileName));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _entryToMarkdown(JournalEntry e) {
    final b = StringBuffer();
    b.writeln('## ${e.title?.isNotEmpty == true ? e.title : e.entryDate}\n');
    b.writeln('日期：${e.entryDate}');
    if (e.mood != null && e.mood!.isNotEmpty) b.writeln('心情：${e.mood}');
    if (e.weather != null && e.weather!.isNotEmpty) b.writeln('天气：${e.weather}');
    b.writeln();
    b.writeln(e.content?.isNotEmpty == true ? e.content : '*暂无内容*');
    return b.toString();
  }

  pw.Page _buildPdfPage(JournalEntry e, pw.Font font) {
    final baseStyle = pw.TextStyle(font: font, fontSize: 12, lineSpacing: 4);
    final titleStyle = pw.TextStyle(
      font: font,
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              e.title?.isNotEmpty == true ? e.title! : e.entryDate,
              style: titleStyle,
            ),
            pw.SizedBox(height: 8),
            pw.Text('日期：${e.entryDate}', style: baseStyle),
            if (e.mood != null && e.mood!.isNotEmpty)
              pw.Text('心情：${e.mood}', style: baseStyle),
            if (e.weather != null && e.weather!.isNotEmpty)
              pw.Text('天气：${e.weather}', style: baseStyle),
            pw.SizedBox(height: 16),
            pw.Text(
              e.content?.isNotEmpty == true ? e.content! : '暂无内容',
              style: baseStyle,
            ),
          ],
        );
      },
    );
  }
}
