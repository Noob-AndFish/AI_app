// 过期任务页
// 展示所有日期早于今天且未完成的任务，允许补打卡

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../today/task_provider.dart';

class TaskOverduePage extends StatefulWidget {
  const TaskOverduePage({super.key});

  @override
  State<TaskOverduePage> createState() => _TaskOverduePageState();
}

class _TaskOverduePageState extends State<TaskOverduePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadOverdue();
    });
  }

  // 计算逾期天数
  int _overdueDays(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final todayClean = DateTime(today.year, today.month, today.day);
      final dateClean = DateTime(date.year, date.month, date.day);
      return todayClean.difference(dateClean).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('过期任务')),
      body: provider.overdueItems.isEmpty
          ? _buildEmptyState(theme)
          : Column(
              children: [
                // 顶部统计条
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: Colors.orange.withOpacity(0.08),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.overdueCount} 个任务已逾期',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 列表
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadOverdue(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: provider.overdueItems.length,
                      itemBuilder: (context, index) {
                        final item = provider.overdueItems[index];
                        final days = _overdueDays(item.occurrence.date);
                        return _OverdueTaskCard(
                          item: item,
                          overdueDays: days,
                          onToggle: () => provider
                              .toggleOverdueComplete(item.occurrence.id!),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: Colors.green.shade400),
          const SizedBox(height: 16),
          Text(
            '没有过期任务，棒棒的 🎉',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// 过期任务卡片
class _OverdueTaskCard extends StatelessWidget {
  final TodayTaskItem item;
  final int overdueDays;
  final VoidCallback onToggle;

  const _OverdueTaskCard({
    required this.item,
    required this.overdueDays,
    required this.onToggle,
  });

  Color _priorityColor(ThemeData theme) {
    if (item.task.priority <= 2) return theme.colorScheme.outline;
    if (item.task.priority == 3) return theme.colorScheme.primary;
    return Colors.orange;
  }

  String get _priorityLabel {
    if (item.task.priority <= 2) return '低';
    if (item.task.priority == 3) return '中';
    return '高';
  }

  // 格式化原始日期
  String get _dateLabel {
    try {
      final d = DateTime.parse(item.occurrence.date);
      return DateFormat('MM-dd').format(d);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = _priorityColor(theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // 复选框
              Icon(
                item.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 24,
                color: item.completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              // 任务名 + 日期
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.task.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.completed
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _dateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '已逾期 $overdueDays 天',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 优先级徽章
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _priorityLabel,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: pColor),
                ),
              ),
              // 连续天数
              if (item.streak > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🔥 ${item.streak} 天',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.orange),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
