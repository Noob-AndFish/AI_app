// JournalProvider
// 日记的状态管理：加载列表、搜索、切换收藏

import 'package:flutter/material.dart';
import '../../data/models/journal_entry.dart';
import '../../data/repositories/journal_repository.dart';

class JournalProvider extends ChangeNotifier {
  final JournalRepository _repo;

  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 是否只看收藏
  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;

  JournalProvider([JournalRepository? repo])
      : _repo = repo ?? JournalRepository();

  // 加载列表
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    if (_showFavoritesOnly) {
      _entries = await _repo.getFavorites();
    } else {
      _entries = await _repo.getAll();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 切换收藏视图
  Future<void> toggleFavoritesView() async {
    _showFavoritesOnly = !_showFavoritesOnly;
    await load();
  }

  // 切换收藏
  Future<void> toggleFavorite(int id) async {
    final entry = _entries.firstWhere((e) => e.id == id);
    await _repo.toggleFavorite(id, entry.favorite);
    await load();
  }

  // 删除
  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }

  // 新建日记
  Future<int> createEntry({
    String? title,
    String? content,
    String? mood,
    String? weather,
    required String entryDate,
  }) async {
    final id = await _repo.create(
      title: title,
      content: content,
      mood: mood,
      weather: weather,
      entryDate: entryDate,
    );
    await load();
    return id;
  }

  // 更新日记
  Future<void> updateEntry(JournalEntry entry) async {
    await _repo.update(entry);
    await load();
  }

  // 按日期查询（编辑页判断当天是否已有日记）
  Future<JournalEntry?> getByDate(String entryDate) {
    return _repo.getByDate(entryDate);
  }

  // 获取所有日记日期（日历页用）
  Future<Map<String, bool>> getAllDates() {
    return _repo.getAllDates();
  }

  // 数量
  Future<int> count() => _repo.count();
}
