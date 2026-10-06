import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_helper.dart';

abstract class BaseRepository<T> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get database async => await _dbHelper.database;

  String get tableName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);

  Future<int> insert(T item) async {
    final db = await database;
    return await db.insert(tableName, toMap(item));
  }

  Future<int> update(T item, {String? whereColumn, dynamic whereValue}) async {
    final db = await database;
    final map = toMap(item);
    final id = map['id'];
    return await db.update(
      tableName,
      map,
      where: whereColumn != null ? '$whereColumn = ?' : 'id = ?',
      whereArgs: whereValue != null ? [whereValue] : [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<T?> getById(int id) async {
    final db = await database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return fromMap(maps.first);
    return null;
  }

  Future<List<T>> getAll({String? orderBy, int? limit, int? offset}) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      orderBy: orderBy ?? 'id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(fromMap).toList();
  }

  Future<int> count({String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
