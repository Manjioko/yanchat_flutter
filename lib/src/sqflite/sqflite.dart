import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // 私有的静态实例
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // 私有的构造函数
  DatabaseHelper._internal();

  // 工厂构造函数
  factory DatabaseHelper() {
    return _instance;
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'test.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // await db.execute(
        //   'CREATE TABLE IF NOT EXISTS userInfo (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        // );
      },
    );
  }

  Future<Database> getDataBase() async {
    Database db = await database;
    return db;
  }
}