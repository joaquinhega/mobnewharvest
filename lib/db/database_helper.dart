import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user.dart'; 

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 2, // Aumentamos la versión para aplicar cambios
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            letra TEXT,
            nombre TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE users ADD COLUMN letra TEXT
          ''');
          await db.execute('''
            ALTER TABLE users ADD COLUMN nombre TEXT
          ''');
        }
      },
    );
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getLoggedInUser() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query('users');

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<void> deleteUser() async {
    final db = await database;
    await db.delete('users');
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    await databaseFactory.deleteDatabase(path);
    _database = null; // Asegurarse de que la referencia a la base de datos se restablezca
  }
}