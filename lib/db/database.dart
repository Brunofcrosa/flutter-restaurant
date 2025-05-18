import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    const dbName = 'restaurante.db';
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cpf TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL DEFAULT 0.0,
        quantidade INTEGER DEFAULT 1,
        finalizado BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Dados iniciais para teste
    await db.insert('users', {
      'cpf': '12345678900',
      'password': '123456',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE itens ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
    }
  }

  // Métodos para Usuários
  Future<bool> login(String cpf, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'cpf = ? AND password = ?',
      whereArgs: [cpf, password],
    );
    return result.isNotEmpty;
  }

  // Métodos para Itens da Comanda
  Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('itens', item);
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await database;
    return await db.query('itens', orderBy: 'created_at DESC');
  }

  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'itens',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('itens', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}