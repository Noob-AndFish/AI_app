// 任务编辑页
// 新建或编辑任务：名称、描述、优先级、起止日期、重复规则

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/task.dart';
import '../../shared/services/notification_service.dart';
import '../today/task_provider.dart';

class TaskEditPage extends StatefulWidget {
  final Task? task; // null 表示新建

  const TaskEditPage({super.key, this.task});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _intervalController;
  late int _priority; // 1-5
  late DateTime _startDate;
  DateTime? _endDate;
  late RepeatType _repeatType;
  late Set<int> _weekdays; // 每周的哪几天（1=周一 ... 7=周日）
  late int _customInterval; // 自定义间隔天数
  TimeOfDay? _reminderTime; // 提醒时间（null=不提醒）
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _nameController = TextEditingController(text: t?.name ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _intervalController = TextEditingController(
      text: (t?.repeatRule.interval ?? 1).toString(),
    );
    _priority = t?.priority ?? 3;
    _startDate = t != null ? DateTime.parse(t.startDate) : DateTime.now();
    _endDate = t?.endDate != null ? DateTime.parse(t!.endDate!) : null;
    _repeatType = t?.repeatRule.type ?? RepeatType.none;
    _weekdays = Set<int>.from(t?.repeatRule.weekdays ?? [1, 3, 5]);
    _customInterval = t?.repeatRule.interval ?? 1;
    // 编辑模式：加载已有提醒
    if (t?.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final reminder = await context.read<TaskProvider>().getTaskReminder(t!.id!);
        if (reminder != null && mounted) {
          setState(() {
            _reminderTime = TimeOfDay(hour: reminder[0], minute: reminder[1]);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  // 构建 RepeatRule
  RepeatRule _buildRule() {
    switch (_repeatType) {
      case RepeatType.none:
        return RepeatRule.none();
      case RepeatType.daily:
        return RepeatRule.daily();
      case RepeatType.weekday:
        return RepeatRule.weekday();
      case RepeatType.weekly:
        return RepeatRule.weekly(_weekdays.toList()..sort());
      case RepeatType.monthly:
        return RepeatRule.monthly();
      case RepeatType.custom:
        final days = int.tryParse(_intervalController.text) ?? 1;
        return RepeatRule.custom(days < 1 ? 1 : days);
    }
  }

  // 日期格式化为 YYYY-MM-DD
  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // 选日期
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // 起始日期若晚于结束日期，清掉结束日期
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  // 保存
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写任务名称')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final rule = _buildRule();
    final provider = context.read<TaskProvider>();

    // 如果设了提醒，先申请通知权限
    if (_reminderTime != null) {
      await NotificationService.instance.requestPermission();
    }

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priority: _priority,
        repeatRule: rule,
        startDate: _fmtDate(_startDate),
        endDate: _endDate != null ? _fmtDate(_endDate!) : null,
      );
      if (_reminderTime != null) {
        await provider.updateTask(
          updated,
          remindHour: _reminderTime!.hour,
          remindMinute: _reminderTime!.minute,
        );
      } else {
        // 编辑时如果清了提醒，取消旧通知
        await provider.clearTaskReminder(widget.task!.id!);
        await provider.updateTask(updated);
      }
    } else {
      await provider.createTask(
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priority: _priority,
        repeatRule: rule,
        startDate: _fmtDate(_startDate),
        endDate: _endDate != null ? _fmtDate(_endDate!) : null,
        remindHour: _reminderTime?.hour,
        remindMinute: _reminderTime?.minute,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
    );
    Navigator.pop(context);
  }

  // 删除
  Future<void> _delete() async {
    if (widget.task?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定删除"${widget.task!.name}"吗？\n所有打卡记录也会被清除。'),
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

    await context.read<TaskProvider>().deleteTask(widget.task!.id!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑任务' : '新建任务'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除',
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '保存',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '任务名称 *',
                hintText: '例如：喝水',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task_alt),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            // 描述
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '任务的具体说明...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),
            // 优先级
            Text('优先级', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildPrioritySelector(theme),
            const SizedBox(height: 16),
            // 日期
            Text('日期', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    theme: theme,
                    label: '开始',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTile(
                    theme: theme,
                    label: '结束（可选）',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                    isOptional: true,
                    onClear: _endDate != null
                        ? () => setState(() => _endDate = null)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 重复规则
            Text('重复', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildRepeatSelector(theme),
            const SizedBox(height: 16),
            // 提醒时间
            Text('提醒', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildReminderTile(theme),
          ],
        ),
      ),
    );
  }

  // 优先级选择器：5 个圆点
  Widget _buildPrioritySelector(ThemeData theme) {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final selected = _priority >= level;
        Color color;
        if (level <= 2) {
          color = theme.colorScheme.outline;
        } else if (level == 3) {
          color = theme.colorScheme.primary;
        } else {
          color = Colors.orange;
        }
        return GestureDetector(
          onTap: () => setState(() => _priority = level),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              selected ? Icons.circle : Icons.circle_outlined,
              size: 28,
              color: selected ? color : theme.dividerColor,
            ),
          ),
        );
      }),
    );
  }

  // 日期卡片
  Widget _buildDateTile({
    required ThemeData theme,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isOptional = false,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        child: Text(
          date != null ? _fmtDate(date) : (isOptional ? '不结束' : '未选择'),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  // 重复规则选择器
  Widget _buildRepeatSelector(ThemeData theme) {
    final options = [
      (RepeatType.none, '不重复'),
      (RepeatType.daily, '每天'),
      (RepeatType.weekday, '工作日'),
      (RepeatType.weekly, '每周'),
      (RepeatType.monthly, '每月'),
      (RepeatType.custom, '自定义'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 芯片横向滚动
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (type, label) = options[index];
              final selected = _repeatType == type;
              return GestureDetector(
                onTap: () => setState(() => _repeatType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 每周选星期几
        if (_repeatType == RepeatType.weekly) ...[
          const SizedBox(height: 12),
          _buildWeekdaySelector(theme),
        ],
        // 自定义间隔
        if (_repeatType == RepeatType.custom) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('每'),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _intervalController,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              const Text('天重复一次'),
            ],
          ),
        ],
      ],
    );
  }

  // 星期几选择器：7 个圆按钮
  Widget _buildWeekdaySelector(ThemeData theme) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1; // 1=周一 ... 7=周日
        final selected = _weekdays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _weekdays.remove(day);
              } else {
                _weekdays.add(day);
              }
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // 提醒时间选择行
  Widget _buildReminderTile(ThemeData theme) {
    return InkWell(
      onTap: _pickReminderTime,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '提醒时间',
          prefixIcon: Icon(
            _reminderTime != null ? Icons.alarm : Icons.alarm_off_outlined,
            color: _reminderTime != null ? theme.colorScheme.primary : null,
          ),
          suffixIcon: _reminderTime != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _reminderTime = null),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        child: Text(
          _reminderTime != null
              ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
              : '不提醒',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  // 选提醒时间
  Future<void> _pickReminderTime() async {
    // 如果已有提醒，点 X 清除；这里只处理选择
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? now,
      helpText: '选择提醒时间',
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }
}
