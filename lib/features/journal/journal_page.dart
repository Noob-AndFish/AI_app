// 日记本列表页
// 按日期降序展示日记，显示心情、标题、正文预览、收藏标记

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/journal_entry.dart';
import '../../shared/widgets/lock_screen.dart';
import 'journal_calendar_page.dart';
import 'journal_edit_page.dart';
import 'journal_provider.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().load();
    });
  }

  // 格式化日期显示：今天 / 昨天 / 09-14
  String _formatDisplayDate(String entryDate) {
    try {
      final d = DateTime.parse(entryDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      if (d.isAtSameMomentAs(today)) return '今天';
      if (d.isAtSameMomentAs(yesterday)) return '昨天';
      return DateFormat('MM-dd').format(d);
    } catch (_) {
      return entryDate;
    }
  }

  // 打开日记：如果已加锁，先验证身份
  Future<void> _openEntry(JournalEntry entry) async {
    if (entry.locked) {
      final ok = await LockScreen.verifyAccess(context, title: '查看日记');
      if (!ok) return;
      if (!mounted) return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JournalEditPage(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.showFavoritesOnly ? '收藏日记' : '日记本'),
        actions: [
          // 收藏/普通切换
          IconButton(
            icon: Icon(provider.showFavoritesOnly
                ? Icons.inbox_outlined
                : Icons.star_border),
            tooltip: provider.showFavoritesOnly ? '返回全部' : '查看收藏',
            onPressed: () => provider.toggleFavoritesView(),
          ),
          // 日历
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: '日历',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JournalCalendarPage(),
                ),
              ).then((_) => provider.load());
            },
          ),
          // 搜索（占位）
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('搜索功能即将上线'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading && provider.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.entries.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: provider.entries.length,
                    itemBuilder: (context, index) {
                      final entry = provider.entries[index];
                      return _JournalCard(
                        entry: entry,
                        displayDate: _formatDisplayDate(entry.entryDate),
                        onTap: () => _openEntry(entry),
                        onToggleFavorite: () =>
                            provider.toggleFavorite(entry.id!),
                        onDelete: () => _confirmDelete(context, provider, entry),
                      );
                    },
                  ),
                ),
      // 新建按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const JournalEditPage(),
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
            Icons.edit_note,
            size: 64,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 16),
          Text(
            provider_showFavoritesOnly_checkMessage(context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // 空状态文案
  String provider_showFavoritesOnly_checkMessage(BuildContext context) {
    final provider = context.read<JournalProvider>();
    if (provider.showFavoritesOnly) {
      return '还没有收藏的日记';
    }
    return '还没有日记\n点右下角 + 开始记录';
  }

  // 删除确认
  Future<void> _confirmDelete(
    BuildContext context,
    JournalProvider provider,
    JournalEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: Text('确定删除 ${entry.entryDate} 的日记吗？'),
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
    if (confirmed == true) {
      await provider.delete(entry.id!);
    }
  }
}

// 日记卡片
class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final String displayDate;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const _JournalCard({
    required this.entry,
    required this.displayDate,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：日期 + 心情 + 收藏 + 菜单
              Row(
                children: [
                  // 日期
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayDate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 心情
                  if (entry.mood != null && entry.mood!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(entry.mood!, style: const TextStyle(fontSize: 20)),
                  ],
                  // 天气
                  if (entry.weather != null &&
                      entry.weather!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      entry.weather!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // 收藏星
                  if (entry.favorite)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                    ),
                  // 隐私锁
                  if (entry.locked)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  // 菜单
                  _buildMenu(context),
                ],
              ),
              // 标题
              if (entry.title?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  entry.title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // 正文预览
              if (entry.content?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  entry.content!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 卡片右上角菜单
  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case 'favorite':
            onToggleFavorite();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'favorite',
          child: Row(children: [
            Icon(entry.favorite ? Icons.star_border : Icons.star),
            const SizedBox(width: 8),
            Text(entry.favorite ? '取消收藏' : '收藏'),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('删除', style: TextStyle(color: Colors.red)),
          ]),
        ),
      ],
    );
  }
}
