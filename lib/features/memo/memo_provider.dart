// MemoProvider
// 备忘录的状态管理：加载列表、搜索、切换归档视图、置顶/归档/删除

import 'package:flutter/material.dart';
import '../../data/models/memo.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/memo_repository.dart';
import '../../data/repositories/tag_repository.dart';

class MemoProvider extends ChangeNotifier {
  final MemoRepository _repo;
  final TagRepository _tagRepo;

  // 列表数据
  List<Memo> _memos = [];
  List<Memo> get memos => _memos;

  // 所有标签
  List<Tag> _allTags = [];
  List<Tag> get allTags => _allTags;

  // 每条备忘录的标签 {memoId: [Tag]}
  Map<int, List<Tag>> _memoTags = {};
  Map<int, List<Tag>> get memoTags => _memoTags;

  // 按标签过滤（null 表示不过滤）
  int? _filterTagId;
  int? get filterTagId => _filterTagId;

  // 是否在看归档
  bool _showArchived = false;
  bool get showArchived => _showArchived;

  // 搜索关键字（空表示不搜）
  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;
  bool get isSearching => _searchKeyword.isNotEmpty;

  // 排序
  MemoSortBy _sortBy = MemoSortBy.updatedAtDesc;
  MemoSortBy get sortBy => _sortBy;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MemoProvider([MemoRepository? repo, TagRepository? tagRepo])
      : _repo = repo ?? MemoRepository(),
        _tagRepo = tagRepo ?? TagRepository();

  // 加载列表
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    // 并行加载列表和标签
    final results = await Future.wait([
      _loadMemos(),
      _tagRepo.getAll(),
    ]);
    _memos = results[0] as List<Memo>;
    _allTags = results[1] as List<Tag>;

    // 加载每条备忘录的标签
    _memoTags.clear();
    for (final memo in _memos) {
      if (memo.id != null) {
        _memoTags[memo.id!] = await _tagRepo.getTagsForMemo(memo.id!);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // 内部：根据过滤条件加载备忘录
  Future<List<Memo>> _loadMemos() async {
    if (_showArchived) {
      return _repo.getArchived(sortBy: _sortBy);
    }
    if (isSearching) {
      return _repo.search(_searchKeyword);
    }
    // 按标签过滤
    if (_filterTagId != null) {
      return _filterByTag(_filterTagId!);
    }
    return _repo.getAll(sortBy: _sortBy, includeArchived: false);
  }

  // 按标签过滤
  Future<List<Memo>> _filterByTag(int tagId) async {
    // 查所有有这个标签的 memo_id
    final db = await _repo.getAll(); // 取全部再过滤
    final result = <Memo>[];
    for (final memo in db) {
      if (memo.id == null) continue;
      final tags = await _tagRepo.getTagsForMemo(memo.id!);
      if (tags.any((t) => t.id == tagId)) {
        result.add(memo);
      }
    }
    return result;
  }

  // 设置标签过滤
  Future<void> filterByTag(int? tagId) async {
    _filterTagId = tagId;
    _searchKeyword = '';
    _showArchived = false;
    await load();
  }

  // 切换归档视图
  Future<void> toggleArchivedView() async {
    _showArchived = !_showArchived;
    _searchKeyword = ''; // 切视图清空搜索
    await load();
  }

  // 设置搜索关键字（空字符串=清空搜索）
  Future<void> setSearch(String keyword) async {
    _searchKeyword = keyword.trim();
    _showArchived = false; // 搜索时强制看非归档
    await load();
  }

  // 设置排序
  Future<void> setSort(MemoSortBy sortBy) async {
    _sortBy = sortBy;
    await load();
  }

  // 切置顶
  Future<void> togglePinned(int id) async {
    final memo = _memos.firstWhere((m) => m.id == id);
    await _repo.setPinned(id, !memo.pinned);
    await load();
  }

  // 切归档
  Future<void> toggleArchived(int id) async {
    final memo = _memos.firstWhere((m) => m.id == id);
    await _repo.setArchived(id, !memo.archived);
    await load();
  }

  // 删除
  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }

  // 取数量统计
  Future<int> activeCount() => _repo.count(includeArchived: false);
  Future<int> archivedCount() async {
    final all = await _repo.count(includeArchived: true);
    final active = await _repo.count(includeArchived: false);
    return all - active;
  }

  // 新建或更新（id 为 null 时新建，否则更新）
  // 返回保存后的 memo id
  Future<int> save({
    int? id,
    required String? title,
    required String? content,
    String? color,
    int isPinned = 0,
    int isArchived = 0,
  }) async {
    int savedId;
    if (id == null) {
      // 新建
      savedId = await _repo.create(title: title, content: content, color: color);
    } else {
      // 更新
      final existing = await _repo.getById(id);
      if (existing != null) {
        final updated = existing.copyWith(
          title: title,
          content: content,
          color: color,
          isPinned: isPinned,
          isArchived: isArchived,
        );
        await _repo.update(updated);
      }
      savedId = id;
    }
    await load();
    return savedId;
  }

  // 设置颜色标记
  Future<void> setColor(int id, String? color) async {
    await _repo.setColor(id, color);
    await load();
  }

  // 给备忘录设置标签（替换式）
  Future<void> setMemoTags(int memoId, List<int> tagIds) async {
    await _tagRepo.setTagsForMemo(memoId, tagIds);
    await load();
  }

  // 新建标签
  Future<Tag> createTag(String name, {String? color}) async {
    final existing = await _tagRepo.getByName(name);
    if (existing != null) return existing;
    final id = await _tagRepo.create(name, color: color);
    final now = DateTime.now().toIso8601String();
    return Tag(id: id, name: name, color: color, createdAt: now);
  }

  // 删除标签
  Future<void> deleteTag(int tagId) async {
    await _tagRepo.delete(tagId);
    if (_filterTagId == tagId) _filterTagId = null;
    await load();
  }
}
