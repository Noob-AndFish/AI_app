// 数据库助手
// 单例模式管理 SQLite 数据库
// 负责：打开数据库、建表、版本升级

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';

class DatabaseHelper {
  // 单例
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  // 获取数据库实例（懒加载）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取应用文档目录
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, AppConstants.dbName);

    // 打开数据库（不存在则创建）
    return await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 首次创建数据库时执行：建表
  Future<void> _onCreate(Database db, int version) async {
    // ===== 1. tags 标签表 =====
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // ===== 2. memos 备忘录表 =====
    await db.execute('''
      CREATE TABLE memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        color TEXT,
        is_pinned INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ===== 3. memo_tags 备忘录-标签关联 =====
    await db.execute('''
      CREATE TABLE memo_tags (
        memo_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (memo_id, tag_id),
        FOREIGN KEY (memo_id) REFERENCES memos(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // ===== 4. tasks 任务定义表 =====
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        priority INTEGER DEFAULT 3,
        repeat_rule TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // ===== 5. task_occurrences 任务实例表 =====
    await db.execute('''
      CREATE TABLE task_occurrences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        UNIQUE (task_id, date),
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    // ===== 6. task_completions 完成打卡表 =====
    await db.execute('''
      CREATE TABLE task_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        completion_date TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    // ===== 7. journal_entries 日记表 =====
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        mood TEXT,
        weather TEXT,
        entry_date TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        is_locked INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ===== 8. journal_tags 日记-标签关联 =====
    await db.execute('''
      CREATE TABLE journal_tags (
        journal_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (journal_id, tag_id),
        FOREIGN KEY (journal_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // ===== 9. attachments 附件表 =====
    await db.execute('''
      CREATE TABLE attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_type TEXT NOT NULL,
        owner_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // ===== 10. reminders 提醒表 =====
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_type TEXT NOT NULL,
        owner_id INTEGER NOT NULL,
        remind_at TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1
      )
    ''');

    // ===== 11. app_settings 应用设置表 =====
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // ===== 创建索引（加速查询） =====
    await db.execute('CREATE INDEX idx_memos_pinned ON memos(is_pinned)');
    await db.execute('CREATE INDEX idx_memos_archived ON memos(is_archived)');
    await db.execute('CREATE INDEX idx_memos_updated ON memos(updated_at)');
    await db.execute('CREATE INDEX idx_tasks_active ON tasks(is_active)');
    await db.execute('CREATE INDEX idx_task_occ_date ON task_occurrences(date)');
    await db.execute('CREATE INDEX idx_task_comp_date ON task_completions(completion_date)');
    await db.execute('CREATE INDEX idx_journal_date ON journal_entries(entry_date)');
    await db.execute('CREATE INDEX idx_journal_fav ON journal_entries(is_favorite)');
    await db.execute('CREATE INDEX idx_attachments_owner ON attachments(owner_type, owner_id)');
    await db.execute('CREATE INDEX idx_reminders_time ON reminders(remind_at)');
  }

  // 版本升级时执行（后续加表/加字段在这里写）
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 当前是 v1，暂无升级逻辑
    // 后续版本升级时在这里加 ALTER TABLE 语句
  }

  // 关闭数据库（App 退出时调用，一般不需要手动调）
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
