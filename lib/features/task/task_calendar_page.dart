// 任务日历页
// 月历视图查看任意一天的任务完成情况，非今天只读

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/repositories/task_repository.dart';
import '../today/task_provider.dart';

// 某天的任务状态（用于日历圆点）
class _DayStatus {
  final bool hasTasks;
  final bool allCompleted;
  const _DayStatus({required this.hasTasks, required this.allCompleted});
}

class TaskCalendarPage extends StatefulWidget {
  const TaskCalendarPage({super.key});

  @override
  State<TaskCalendarPage> createState() => _TaskCalendarPageState();
}

class _TaskCalendarPageState extends State<TaskCalendarPage> {
  final _repo = TaskRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<TodayTaskItem> _items = [];
  Map<String, _DayStatus> _statusMap = {};
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedDayItems();
    _loadMonthStatus(_focusedDay);
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime day) => _isSameDay(day, DateTime.now());

  // 加载选中当天的任务列表（带任务详情和连续天数）
  Future<void> _loadSelectedDayItems() async {
    setState(() => _isLoadingItems = true);
    final dateStr = _fmtDate(_selectedDay);
    final occurrences = await _repo.getOccurrencesForDate(dateStr);
    final items = <TodayTaskItem>[];
    for (final occ in occurrences) {
      final task = await _repo.getById(occ.taskId);
      if (task == null) continue;
      final streak = await _repo.getStreak(task.id!);
      items.add(TodayTaskItem(
        occurrence: occ,
        task: task,
        streak: streak,
      ));
    }
    _items = items;
    if (mounted) setState(() => _isLoadingItems = false);
  }

  // 加载整个月的每天任务状态（用于圆点标记）
  Future<void> _loadMonthStatus(DateTime monthDate) async {
    final firstOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final statusMap = <String, _DayStatus>{};
    for (var d = firstOfMonth;
        !d.isAfter(lastOfMonth);
        d = d.add(const Duration(days: 1))) {
      final dateStr = _fmtDate(d);
      final occurrences = await _repo.getOccurrencesForDate(dateStr);
      if (occurrences.isEmpty) continue;
      final allCompleted = occurrences.every((o) => o.completed);
      statusMap[dateStr] =
          _DayStatus(hasTasks: true, allCompleted: allCompleted);
    }
    if (!mounted) return;
    setState(() => _statusMap = statusMap);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadSelectedDayItems();
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    _loadMonthStatus(focusedDay);
  }

  // 只有今天可打卡
  Future<void> _toggleIfToday(int occurrenceId) async {
    if (!_isToday(_selectedDay)) return;
    await context.read<TaskProvider>().toggleComplete(occurrenceId);
    await _loadSelectedDayItems();
    await _loadMonthStatus(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: Column(
        children: [
          // 月历
          TableCalendar<bool>(
            firstDay: DateTime(now.year - 2, 1, 1),
            lastDay: DateTime(now.year + 2, 12, 31),
            focusedDay: _focusedDay,
            currentDay: now,
            selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: '月'},
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextFormatter: (date, locale) =>
                  '${date.year}年${date.month}月',
              titleTextStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) {
                const labels = ['', '一', '二', '三', '四', '五', '六', '日'];
                return labels[date.weekday];
              },
            ),
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              isTodayHighlighted: true,
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: true,
            ),
            eventLoader: (day) {
              final dateStr = _fmtDate(day);
              final status = _statusMap[dateStr];
              if (status == null || !status.hasTasks) return <bool>[];
              return [status.allCompleted];
            },
            calendarBuilders: CalendarBuilders<bool>(
              singleMarkerBuilder: (context, day, event) {
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event ? Colors.green : theme.colorScheme.outline,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 选中日期的头部
          _buildSelectedDayHeader(theme),
          // 任务列表
          Expanded(child: _buildSelectedDayList(theme)),
        ],
      ),
    );
  }

  // 选中日期头部
  Widget _buildSelectedDayHeader(ThemeData theme) {
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekDay = weekDays[_selectedDay.weekday - 1];
    final dateStr = _fmtDate(_selectedDay);
    final count = _items.length;
    final completedCount = _items.where((i) => i.completed).length;
    final isToday = _isToday(_selectedDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '$dateStr $weekDay',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '今日',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            count == 0 ? '无任务' : '$completedCount / $count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: count > 0 && completedCount == count
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // 选中日期的任务列表
  Widget _buildSelectedDayList(ThemeData theme) {
    if (_isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: theme.dividerColor),
            const SizedBox(height: 12),
            Text('当天无任务', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    final canToggle = _isToday(_selectedDay);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _CalendarTaskCard(
          item: item,
          canToggle: canToggle,
          onTap: canToggle
              ? () => _toggleIfToday(item.occurrence.id!)
              : null,
        );
      },
    );
  }
}

// 日历页任务卡片（与今日页样式一致，非今日不可打卡）
class _CalendarTaskCard extends StatelessWidget {
  final TodayTaskItem item;
  final bool canToggle;
  final VoidCallback? onTap;

  const _CalendarTaskCard({
    required this.item,
    required this.canToggle,
    required this.onTap,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = _priorityColor(theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _priorityLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: pColor),
                ),
              ),
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
