// 备忘录编辑页
// 新建或编辑备忘录：标题、正文、颜色标记、置顶/归档

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/models/memo.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/utils/file_helper.dart';
import 'memo_provider.dart';

// 预设颜色（无色 + 8 种）
const List<String?> _presetColors = [
  null, // 无色
  '#F44336', // 红
  '#FF9800', // 橙
  '#FFC107', // 黄
  '#4CAF50', // 绿
  '#00BCD4', // 青
  '#2196F3', // 蓝
  '#9C27B0', // 紫
  '#795548', // 棕
];

class MemoEditPage extends StatefulWidget {
  final Memo? memo; // null 表示新建

  const MemoEditPage({super.key, this.memo});

  @override
  State<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String? _color;
  late bool _isPinned;
  late bool _isArchived;
  bool _isSaving = false;
  bool _isPreview = false; // false=编辑模式，true=预览模式
  // 当前选中的标签 id 集合
  Set<int> _selectedTagIds = {};
  // 缓存的 memo id（保存后才有）
  int? _memoId;
  // 提醒时间（null 表示不提醒）
  DateTime? _reminderAt;

  bool get _isEditing => widget.memo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo?.title ?? '');
    _contentController = TextEditingController(text: widget.memo?.content ?? '');
    _color = widget.memo?.color;
    _isPinned = widget.memo?.pinned ?? false;
    _isArchived = widget.memo?.archived ?? false;
    _memoId = widget.memo?.id;
    // 加载已有标签（编辑模式）
    if (_memoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final tags = await TagRepository().getTagsForMemo(_memoId!);
        setState(() {
          _selectedTagIds = tags.map((t) => t.id!).toSet();
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑备忘录' : '新建备忘录'),
        actions: [
          // 编辑/预览切换
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility_outlined),
            tooltip: _isPreview ? '编辑' : '预览',
            onPressed: () => setState(() => _isPreview = !_isPreview),
          ),
          // 置顶
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? theme.colorScheme.primary : null,
            ),
            tooltip: _isPinned ? '取消置顶' : '置顶',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          // 归档
          IconButton(
            icon: Icon(_isArchived
                ? Icons.archive
                : Icons.archive_outlined),
            tooltip: _isArchived ? '取消归档' : '归档',
            onPressed: () => setState(() => _isArchived = !_isArchived),
          ),
          // 提醒
          IconButton(
            icon: Icon(
              _reminderAt != null
                  ? Icons.alarm
                  : Icons.alarm_add_outlined,
              color: _reminderAt != null
                  ? theme.colorScheme.primary
                  : null,
            ),
            tooltip: _reminderAt != null ? '取消提醒' : '设置提醒',
            onPressed: _pickReminder,
          ),
          // 保存
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '保存',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          // 标签选择
          _buildTagSelector(theme),
          const Divider(),
          // 正文（编辑模式 or 预览模式）
          Expanded(
            child: _isPreview
                ? _buildPreview(theme)
                : _buildEditor(theme),
          ),
          // 颜色选择条
          _buildColorPicker(theme),
          // 工具栏（编辑模式才显示）
          if (!_isPreview) _buildToolbar(theme),
        ],
      ),
    );
  }

  // 标签选择器
  Widget _buildTagSelector(ThemeData theme) {
    final provider = context.watch<MemoProvider>();
    final tags = provider.allTags;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.label_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: tags.isEmpty && _selectedTagIds.isEmpty
                ? Text(
                    '点击 + 添加标签',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // 已选标签
                        for (final tagId in _selectedTagIds)
                          if (tags.any((t) => t.id == tagId))
                            _tagChip(theme, tags.firstWhere((t) => t.id == tagId), selected: true),
                        // 未选标签
                        for (final tag in tags)
                          if (!_selectedTagIds.contains(tag.id))
                            _tagChip(theme, tag, selected: false),
                      ],
                    ),
                  ),
          ),
          // 新建标签
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: '新建标签',
            onPressed: () => _showCreateTagDialog(theme),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // 标签 Chip
  Widget _tagChip(ThemeData theme, Tag tag, {required bool selected}) {
    Color? chipColor;
    if (tag.color != null) {
      try {
        chipColor = Color(int.parse('FF${tag.color!.replaceFirst('#', '')}', radix: 16));
      } catch (_) {}
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedTagIds.remove(tag.id);
          } else {
            _selectedTagIds.add(tag.id!);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? (chipColor ?? theme.colorScheme.primary).withOpacity(0.15)
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (chipColor ?? theme.colorScheme.primary)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chipColor != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
              ),
            Text(
              tag.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? (chipColor ?? theme.colorScheme.primary)
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 新建标签对话框
  Future<void> _showCreateTagDialog(ThemeData theme) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '标签名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final provider = context.read<MemoProvider>();
      final tag = await provider.createTag(result);
      setState(() {
        _selectedTagIds.add(tag.id!);
      });
    }
  }

  // 选择提醒时间
  Future<void> _pickReminder() async {
    // 如果已有提醒，再次点击是取消
    if (_reminderAt != null) {
      setState(() => _reminderAt = null);
      return;
    }

    // 先申请通知权限
    await NotificationService.instance.requestPermission();

    final now = DateTime.now();
    // 先选日期
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;

    // 再选时间
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _reminderAt = reminder);
  }

  // 工具栏
  Widget _buildToolbar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // 插入图片
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: '插入图片',
            onPressed: _pickImage,
          ),
          const Spacer(),
          Text(
            _contentController.text.isEmpty
                ? '0 字'
                : '${_contentController.text.length} 字',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // 选图并插入 Markdown 图片语法
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xFile == null) return; // 用户取消

      // 复制到 attachments 目录
      final relativePath = await FileHelper.copyToAttachments(xFile.path);
      final absPath = await FileHelper.getAbsolutePath(relativePath);

      // 在正文光标处插入 Markdown 图片语法
      final text = _contentController.text;
      final cursor = _contentController.selection.baseOffset;
      final insertText = '\n![](file://$absPath)\n';
      final newText = cursor < 0
          ? '$text$insertText'
          : text.substring(0, cursor) + insertText + text.substring(cursor);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: (cursor < 0 ? text.length : cursor) + insertText.length,
      );
      setState(() {});

      // 如果备忘录已保存，记录到 attachments 表
      if (widget.memo?.id != null) {
        await AttachmentRepository().create(
          ownerType: 'memo',
          ownerId: widget.memo!.id!,
          filePath: relativePath,
          fileType: 'image',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('插入图片失败：$e')),
        );
      }
    }
  }

  // 编辑模式
  Widget _buildEditor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _contentController,
        decoration: const InputDecoration(
          hintText: '写点什么...\n支持 Markdown：# 标题、- 列表、**加粗**、> 引用',
          border: InputBorder.none,
        ),
        style: theme.textTheme.bodyLarge,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        // 输入时实时刷新预览缓存
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // 预览模式
  Widget _buildPreview(ThemeData theme) {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      return Center(
        child: Text(
          '暂无内容',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: MarkdownBody(
          data: content,
          selectable: true,
          // 支持本地 file:// 图片
          imageBuilder: (uri, title, alt) {
            if (uri.scheme == 'file') {
              return Image.file(
                File.fromUri(uri),
                fit: BoxFit.contain,
                errorBuilder: (_, error, ___) => Container(
                  padding: const EdgeInsets.all(8),
                  color: theme.colorScheme.errorContainer,
                  child: Text('图片加载失败：$alt'),
                ),
              );
            }
            // 网络图片走默认
            return Image.network(uri.toString(), errorBuilder: (_, __, ___) {
              return Text('[图片:$alt]');
            });
          },
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: theme.textTheme.bodyLarge,
            h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            blockquote: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            blockquoteDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
              ),
            ),
            code: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            codeblockDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  // 颜色选择条
  Widget _buildColorPicker(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '颜色',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetColors.map((color) {
                  final selected = _color == color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color == null
                            ? theme.scaffoldBackgroundColor
                            : _parseColor(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: color == null
                          ? Icon(
                              Icons.block,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 保存
  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      // 空内容直接返回不保存
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    final savedId = await context.read<MemoProvider>().save(
          id: widget.memo?.id,
          title: title.isEmpty ? null : title,
          content: content.isEmpty ? null : content,
          color: _color,
          isPinned: _isPinned ? 1 : 0,
          isArchived: _isArchived ? 1 : 0,
        );
    // 保存标签关联
    await context.read<MemoProvider>().setMemoTags(savedId, _selectedTagIds.toList());

    // 调度提醒通知
    if (_reminderAt != null) {
      await NotificationService.instance.scheduleNotification(
        id: savedId,
        title: title.isEmpty ? '备忘录提醒' : title,
        body: content.isEmpty ? '你设置了一条备忘录提醒' : content.substring(0, content.length > 50 ? 50 : content.length),
        scheduledDate: _reminderAt!,
      );
    } else if (widget.memo?.id != null) {
      // 编辑模式下取消了提醒，取消已有通知
      await NotificationService.instance.cancel(widget.memo!.id!);
    }

    if (mounted) Navigator.pop(context);
  }

  // 解析颜色
  Color _parseColor(String hex) {
    try {
      final hexValue = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
