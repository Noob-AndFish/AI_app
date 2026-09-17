// 日记日历页
// 按月份查看哪天写了日记，点击进入编辑页

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/journal_entry.dart';
import '../../shared/widgets/lock_screen.dart';
import 'journal_edit_page.dart';
import 'journal_provider.dart';

class JournalCalendarPage extends StatefulWidget {
  const JournalCalendarPage({super.key});

  @override
  State<JournalCalendarPage> createState() => _JournalCalendarPageState();
}

class _JournalCalendarPageState extends State<JournalCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<String, bool> _dateMap = {}; // {entry_date: is_favorite}
  JournalEntry? _selectedEntry;
  bool _isLoadingEntry = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadDateMap();
    _loadSelectedEntry();
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // 加载所有日记日期
  Future<void> _loadDateMap() async {
    final provider = context.read<JournalProvider>();
    _dateMap = await provider.getAllDates();
    if (mounted) setState(() {});
  }

  // 加载选中日期的日记
  Future<void> _loadSelectedEntry() async {
    setState(() => _isLoadingEntry = true);
    final provider = context.read<JournalProvider>();
    _selectedEntry = await provider.getByDate(_formatDate(_selectedDay));
    if (mounted) setState(() => _isLoadingEntry = false);
  }

  // 选择日期
  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    _loadSelectedEntry();
  }

  // 月份切换时重新加载日期图
  void _onFormatChange(CalendarFormat f) {
    _loadDateMap();
  }

  void _onPageChange(DateTime focused) {
    setState(() => _focusedDay = focused);
    _loadDateMap();
  }

  // 进入编辑页（新建或编辑）
  // 如果当前已选中加锁日记，先验证该篇密码
  Future<void> _openEditPage() async {
    if (_selectedEntry != null && _selectedEntry!.locked) {
      final ok = await LockScreen.verifyForEntry(
        context, _selectedEntry!.id!, title: '查看日记');
      if (!ok) return;
      if (!mounted) return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEditPage(entry: _selectedEntry),
      ),
    );
    // 返回后刷新
    _loadDateMap();
    _loadSelectedEntry();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy年M月').format(_focusedDay)),
      ),
      body: Column(
        children: [
          // 日历
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: _onDaySelected,
            onFormatChanged: _onFormatChange,
            onPageChanged: _onPageChange,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(),
            ),
            // 圆点标记
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, focusedDay) {
                final key = _formatDate(day);
                if (!_dateMap.containsKey(key)) return null;
                final isFavorite = _dateMap[key]!;
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFavorite
                          ? Colors.amber.shade600
                          : theme.colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 选中日期的日记
          Expanded(
            child: _buildSelectedDayContent(theme),
          ),
        ],
      ),
      // 新建当天日记
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditPage,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 选中日期下方区域
  Widget _buildSelectedDayContent(ThemeData theme) {
    final dateStr =
        DateFormat('yyyy-MM-dd EEEE', 'zh_CN').format(_selectedDay);
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 日期标题
        Row(
          children: [
            Text(
              dateStr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '今日',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // 内容
        if (_isLoadingEntry)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ))
        else if (_selectedEntry != null)
          _buildEntryCard(theme)
        else
          _buildEmptyState(theme),
      ],
    );
  }

  // 日记卡片
  Widget _buildEntryCard(ThemeData theme) {
    final e = _selectedEntry!;
    return Card(
      child: InkWell(
        onTap: _openEditPage,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (e.mood != null && e.mood!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(e.mood!, style: const TextStyle(fontSize: 22)),
                    ),
                  if (e.weather != null && e.weather!.isNotEmpty)
                    Text(
                      e.weather!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  if (e.favorite)
                    Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                  if (e.locked)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.lock,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              if (e.title?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  e.title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (e.content?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  e.content!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 56, color: theme.dividerColor),
          const SizedBox(height: 12),
          Text('这一天没有日记',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openEditPage,
            icon: const Icon(Icons.edit),
            label: const Text('写一篇'),
          ),
        ],
      ),
    );
  }
}
