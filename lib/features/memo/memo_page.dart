// 备忘录列表页
// 显示所有备忘录，置顶在前，支持搜索、归档切换

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/memo.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/memo_repository.dart';
import 'memo_edit_page.dart';
import 'memo_provider.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 首次进入加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemoProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.showArchived ? '归档备忘录' : '备忘录'),
        actions: [
          // 归档/普通切换
          IconButton(
            icon: Icon(provider.showArchived
                ? Icons.inbox_outlined
                : Icons.archive_outlined),
            tooltip: provider.showArchived ? '返回列表' : '查看归档',
            onPressed: () => provider.toggleArchivedView(),
          ),
          // 排序菜单
          PopupMenuButton<MemoSortBy>(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onSelected: (sortBy) => provider.setSort(sortBy),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MemoSortBy.updatedAtDesc,
                child: Text('更新时间 ↓'),
              ),
              const PopupMenuItem(
                value: MemoSortBy.updatedAtAsc,
                child: Text('更新时间 ↑'),
              ),
              const PopupMenuItem(
                value: MemoSortBy.createdAtDesc,
                child: Text('创建时间 ↓'),
              ),
              const PopupMenuItem(
                value: MemoSortBy.titleAsc,
                child: Text('标题 A-Z'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏（只在非归档视图显示）
          if (!provider.showArchived) _buildSearchBar(theme, provider),
          // 标签过滤条
          if (!provider.showArchived && provider.allTags.isNotEmpty)
            _buildTagFilter(theme, provider),
          // 列表
          Expanded(child: _buildList(context, provider)),
        ],
      ),
      // 新建按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 搜索栏
  Widget _buildSearchBar(ThemeData theme, MemoProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索备忘录...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: provider.isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onChanged: (value) => provider.setSearch(value),
      ),
    );
  }

  // 标签过滤条
  Widget _buildTagFilter(ThemeData theme, MemoProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: provider.allTags.length,
        itemBuilder: (context, index) {
          final tag = provider.allTags[index];
          final selected = provider.filterTagId == tag.id;
          Color? tagColor;
          if (tag.color != null) {
            try {
              tagColor = Color(int.parse('FF${tag.color!.replaceFirst('#', '')}', radix: 16));
            } catch (_) {}
          }
          return GestureDetector(
            onTap: () => provider.filterByTag(selected ? null : tag.id),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? (tagColor ?? theme.colorScheme.primary).withOpacity(0.15)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? (tagColor ?? theme.colorScheme.primary)
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  tag.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? (tagColor ?? theme.colorScheme.primary)
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 列表
  Widget _buildList(BuildContext context, MemoProvider provider) {
    if (provider.isLoading && provider.memos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.memos.isEmpty) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        itemCount: provider.memos.length,
        itemBuilder: (context, index) {
          final memo = provider.memos[index];
          return _MemoCard(
            memo: memo,
            tags: provider.memoTags[memo.id] ?? [],
            onTap: () => _openEditor(context, memo: memo),
            onTogglePin: () => provider.togglePinned(memo.id!),
            onToggleArchive: () => provider.toggleArchived(memo.id!),
            onDelete: () => _confirmDelete(context, provider, memo),
          );
        },
      ),
    );
  }

  // 空状态
  Widget _buildEmptyState(MemoProvider provider) {
    String message;
    IconData icon;
    if (provider.isSearching) {
      message = '没有找到匹配的备忘录';
      icon = Icons.search_off;
    } else if (provider.showArchived) {
      message = '还没有归档的备忘录';
      icon = Icons.archive_outlined;
    } else {
      message = '还没有备忘录\n点右下角 + 新建一条';
      icon = Icons.note_add_outlined;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // 打开编辑页（memo 为 null 表示新建）
  void _openEditor(BuildContext context, {Memo? memo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoEditPage(memo: memo),
        fullscreenDialog: true,
      ),
    );
  }

  // 删除确认
  Future<void> _confirmDelete(
    BuildContext context,
    MemoProvider provider,
    Memo memo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备忘录'),
        content: Text('确定删除"${memo.title ?? '无标题'}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.delete(memo.id!);
    }
  }
}

// 备忘录卡片
class _MemoCard extends StatelessWidget {
  final Memo memo;
  final List<Tag> tags;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleArchive;
  final VoidCallback onDelete;

  const _MemoCard({
    required this.memo,
    required this.tags,
    required this.onTap,
    required this.onTogglePin,
    required this.onToggleArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasColor = memo.color != null && memo.color!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: hasColor
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _parseColor(memo.color!),
                      width: 4,
                    ),
                  ),
                )
              : null,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  if (memo.pinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.push_pin,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      memo.title?.isNotEmpty == true
                          ? memo.title!
                          : '无标题',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildMenu(context),
                ],
              ),
              // 正文预览
              if (memo.content?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  memo.content!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // 时间
              const SizedBox(height: 8),
              Text(
                _formatDate(memo.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // 标签
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) {
                    Color? tagColor;
                    if (tag.color != null) {
                      try {
                        tagColor = Color(int.parse(
                            'FF${tag.color!.replaceFirst('#', '')}',
                            radix: 16));
                      } catch (_) {}
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (tagColor ?? theme.colorScheme.primary)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: (tagColor ?? theme.colorScheme.primary),
                        ),
                      ),
                    );
                  }).toList(),
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
          case 'pin':
            onTogglePin();
            break;
          case 'archive':
            onToggleArchive();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(children: [
            Icon(memo.pinned ? Icons.push_pin_outlined : Icons.push_pin),
            const SizedBox(width: 8),
            Text(memo.pinned ? '取消置顶' : '置顶'),
          ]),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(children: [
            Icon(memo.archived ? Icons.inbox_outlined : Icons.archive_outlined),
            const SizedBox(width: 8),
            Text(memo.archived ? '取消归档' : '归档'),
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

  // 解析颜色
  Color _parseColor(String hex) {
    try {
      final hexValue = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // 格式化日期
  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
