import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user.dart';
import 'combustible_dao.dart';

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
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT UNIQUE,
        password TEXT,
        letra TEXT,
        nombre TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE combustibles (
        id TEXT PRIMARY KEY,
        fecha TEXT,
        monto REAL,
        patente TEXT,
        nombre TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS combustibles (
          id TEXT PRIMARY KEY,
          fecha TEXT,
          monto REAL,
          patente TEXT,
          nombre TEXT
        )
      ''');
    }
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'username = ?',
      whereArgs: [user.username],
    );
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
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

  Future<void> insertCombustible(Combustible combustible) async {
    final db = await database;
    await db.insert(
      'combustibles',
      combustible.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Combustible>> getPendingCombustibles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('combustibles');
    return List.generate(maps.length, (i) {
      return Combustible.fromMap(maps[i]);
    });
  }

  Future<void> deleteCombustible(String id) async {
    final db = await database;
    await db.delete(
      'combustibles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}