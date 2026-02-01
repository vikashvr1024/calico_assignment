import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calico.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create pets table
        await db.execute('''
          CREATE TABLE pets (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            synced INTEGER DEFAULT 1
          )
        ''');

        // Create vaccines table
        await db.execute('''
          CREATE TABLE vaccines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            pet_id INTEGER NOT NULL,
            vaccine_name TEXT NOT NULL,
            date_issued TEXT,
            next_due_date TEXT,
            type TEXT,
            image_url TEXT,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY (pet_id) REFERENCES pets (id)
          )
        ''');

        // Create pending uploads queue
        await db.execute('''
          CREATE TABLE pending_uploads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vaccine_data TEXT NOT NULL,
            image_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('pets');
    await db.delete('vaccines');
    await db.delete('pending_uploads');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
