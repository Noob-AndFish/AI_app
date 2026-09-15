// 日记编辑页
// 新建或编辑日记：日期、标题、正文（Markdown）、心情、天气

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/journal_entry.dart';
import 'journal_provider.dart';

// 心情选项
const List<_MoodOption> _moodOptions = [
  _MoodOption(emoji: '😊', label: '开心'),
  _MoodOption(emoji: '😌', label: '平静'),
  _MoodOption(emoji: '😐', label: '一般'),
  _MoodOption(emoji: '😔', label: '低落'),
  _MoodOption(emoji: '😢', label: '难过'),
];

// 天气选项
const List<_WeatherOption> _weatherOptions = [
  _WeatherOption(emoji: '☀️', label: '晴'),
  _WeatherOption(emoji: '⛅', label: '多云'),
  _WeatherOption(emoji: '☁️', label: '阴'),
  _WeatherOption(emoji: '🌧️', label: '小雨'),
  _WeatherOption(emoji: '⛈️', label: '大雨'),
  _WeatherOption(emoji: '❄️', label: '雪'),
];

class _MoodOption {
  final String emoji;
  final String label;
  const _MoodOption({required this.emoji, required this.label});
}

class _WeatherOption {
  final String emoji;
  final String label;
  const _WeatherOption({required this.emoji, required this.label});
}

class JournalEditPage extends StatefulWidget {
  final JournalEntry? entry; // null 表示新建

  const JournalEditPage({super.key, this.entry});

  @override
  State<JournalEditPage> createState() => _JournalEditPageState();
}

class _JournalEditPageState extends State<JournalEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _selectedDate;
  String? _mood;
  String? _weather;
  bool _isPreview = false; // false=编辑 true=预览
  bool _isSaving = false;
  int? _existingId; // 编辑模式下的日记 id

  bool get _isEditing => _existingId != null;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      // 编辑模式
      _titleController =
          TextEditingController(text: widget.entry!.title ?? '');
      _contentController =
          TextEditingController(text: widget.entry!.content ?? '');
      _mood = widget.entry!.mood;
      _weather = widget.entry!.weather;
      _selectedDate = _parseDate(widget.entry!.entryDate) ?? DateTime.now();
      _existingId = widget.entry!.id;
    } else {
      // 新建模式
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _selectedDate = DateTime.now();
      // 检查今天是否已有日记
      _checkExistingForDate(DateTime.now());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // 检查某天是否已有日记，有则自动加载
  Future<void> _checkExistingForDate(DateTime date) async {
    final provider = context.read<JournalProvider>();
    final existing = await provider.getByDate(_formatDate(date));
    if (existing != null && mounted) {
      setState(() {
        _titleController.text = existing.title ?? '';
        _contentController.text = existing.content ?? '';
        _mood = existing.mood;
        _weather = existing.weather;
        _existingId = existing.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_formatDate(date)} 已有日记，已加载内容'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted && _existingId != null) {
      // 从有日记的日期切到没有的日期：清空表单（变回新建模式）
      setState(() {
        _titleController.clear();
        _contentController.clear();
        _mood = null;
        _weather = null;
        _existingId = null;
      });
    }
  }

  // 选日期
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _checkExistingForDate(picked);
    }
  }

  // 保存
  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题或正文')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<JournalProvider>();

    if (_isEditing) {
      // 更新
      final updated = widget.entry!.copyWith(
        title: title.isEmpty ? null : title,
        content: content.isEmpty ? null : content,
        mood: _mood,
        weather: _weather,
        entryDate: _formatDate(_selectedDate),
      );
      await provider.updateEntry(updated);
    } else {
      // 新建
      await provider.createEntry(
        title: title.isEmpty ? null : title,
        content: content.isEmpty ? null : content,
        mood: _mood,
        weather: _weather,
        entryDate: _formatDate(_selectedDate),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存'), duration: Duration(milliseconds: 800)),
      );
      Navigator.pop(context);
    }
  }

  // 删除
  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: Text('确定删除 ${_formatDate(_selectedDate)} 的日记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final provider = context.read<JournalProvider>();
    await provider.delete(_existingId!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日记' : '新建日记'),
        actions: [
          // 编辑/预览切换
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility_outlined),
            tooltip: _isPreview ? '编辑' : '预览',
            onPressed: () => setState(() => _isPreview = !_isPreview),
          ),
          // 保存
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '保存',
            onPressed: _isSaving ? null : _save,
          ),
          // 删除（仅编辑模式）
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _delete,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期
                  _buildDateRow(theme),
                  const SizedBox(height: 16),
                  // 心情
                  _buildSectionLabel('心情', theme),
                  const SizedBox(height: 8),
                  _buildMoodSelector(theme),
                  const SizedBox(height: 16),
                  // 天气
                  _buildSectionLabel('天气', theme),
                  const SizedBox(height: 8),
                  _buildWeatherSelector(theme),
                  const SizedBox(height: 16),
                  // 标题
                  _buildSectionLabel('标题', theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '给今天起个标题（可选）',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 正文
                  _buildSectionLabel('正文（支持 Markdown）', theme),
                  const SizedBox(height: 8),
                  if (_isPreview)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minHeight: 200),
                      child: MarkdownBody(
                        data: _contentController.text.isEmpty
                            ? '*暂无内容*'
                            : _contentController.text,
                      ),
                    )
                  else
                    TextField(
                      controller: _contentController,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        hintText: '记录今天的故事...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // 图片附件占位
                  _buildSectionLabel('图片', theme),
                  const SizedBox(height: 8),
                  _buildImagePlaceholder(theme),
                ],
              ),
            ),
    );
  }

  // 日期行
  Widget _buildDateRow(ThemeData theme) {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy-MM-dd EEEE', 'zh_CN').format(_selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  // 心情选择器
  Widget _buildMoodSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: _moodOptions.map((m) {
        final selected = _mood == m.emoji;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text(m.label),
            ],
          ),
          selected: selected,
          onSelected: (_) => setState(() => _mood = selected ? null : m.emoji),
        );
      }).toList(),
    );
  }

  // 天气选择器
  Widget _buildWeatherSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _weatherOptions.map((w) {
        final selected = _weather == w.emoji;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(w.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(w.label),
            ],
          ),
          selected: selected,
          onSelected: (_) =>
              setState(() => _weather = selected ? null : w.emoji),
        );
      }).toList(),
    );
  }

  // 图片附件占位
  Widget _buildImagePlaceholder(ThemeData theme) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片附件即将上线'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text('添加图片',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
