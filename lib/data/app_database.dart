import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._({Database? database}) : _database = database;

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = p.join(databasesPath, 'cpd_test_app.db');
    final openedDatabase = await openDatabase(
      databasePath,
      version: 2,
      onConfigure: _configureDatabase,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  static Future<AppDatabase> openInMemoryForTest() async {
    final database = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onConfigure: _configureDatabase,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    return AppDatabase._(database: database);
  }

  Future<void> close() async {
    final existingDatabase = _database;
    if (existingDatabase == null) {
      return;
    }

    await existingDatabase.close();
    _database = null;
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE auth_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await _createPostsTable(db);
  }

  static Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createPostsTable(db);
    }
  }

  static Future<void> _createPostsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_posts_created_at
      ON posts (created_at DESC, id DESC)
    ''');
  }

  static Future<void> _configureDatabase(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }
}
