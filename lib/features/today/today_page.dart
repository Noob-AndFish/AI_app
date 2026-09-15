// 今日页面
// 展示今日任务、打卡、进度

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../task/task_calendar_page.dart';
import '../task/task_edit_page.dart';
import '../task/task_overdue_page.dart';
import 'task_provider.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  void initState() {
    super.initState();
    // 首次进入加载今日任务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadToday();
    });
  }

  // 格式化日期：2026-09-14 周一
  String _formatToday() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '$dateStr ${weekDays[now.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('今日 · ${_formatToday()}'),
        actions: [
          // 过期任务按钮（带红色数字徽章）
          if (provider.overdueCount > 0)
            IconButton(
              icon: Badge(
                label: Text(
                  '${provider.overdueCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: Colors.red,
                child: const Icon(Icons.warning_amber_rounded),
              ),
              tooltip: '过期任务',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskOverduePage(),
                  ),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.warning_amber_outlined),
              tooltip: '过期任务',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskOverduePage(),
                  ),
                );
              },
            ),
          // 日历按钮
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: '日历',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskCalendarPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadToday(),
        child: provider.isLoading && provider.todayItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // 进度卡
                  SliverToBoxAdapter(
                    child: _ProgressCard(
                      total: provider.total,
                      completed: provider.completedCount,
                      progress: provider.progress,
                    ),
                  ),
                  // 列表或空状态
                  if (provider.todayItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(theme),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      sliver: SliverList.builder(
                        itemCount: provider.todayItems.length,
                        itemBuilder: (context, index) {
                          final item = provider.todayItems[index];
                          return _TaskCard(
                            item: item,
                            onToggle: () => provider
                                .toggleComplete(item.occurrence.id!),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      // 新建任务
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskEditPage(),
              fullscreenDialog: true,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 64,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有任务\n去「任务」页新建一条',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// 进度卡
class _ProgressCard extends StatelessWidget {
  final int total;
  final int completed;
  final double progress;

  const _ProgressCard({
    required this.total,
    required this.completed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日进度',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$completed / $total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                // 没任务时显示不确定动画；有任务但完成率0时显示 0
                value: total == 0 ? null : progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              total == 0 ? '今日无任务' : '完成率 $percent%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 任务卡片
class _TaskCard extends StatelessWidget {
  final TodayTaskItem item;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.item,
    required this.onToggle,
  });

  // 优先级颜色
  Color _priorityColor(ThemeData theme) {
    if (item.task.priority <= 2) return theme.colorScheme.outline;
    if (item.task.priority == 3) return theme.colorScheme.primary;
    return Colors.orange;
  }

  // 优先级文字
  String get _priorityLabel {
    if (item.task.priority <= 2) return '低';
    if (item.task.priority == 3) return '中';
    return '高';
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
              // 任务名 + 描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.task.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.completed
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.task.description?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.task.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 优先级徽章
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _priorityLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: pColor,
                  ),
                ),
              ),
              // 连续天数徽章
              if (item.streak > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🔥 ${item.streak} 天',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                    ),
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
