import 'package:colla_chat/datastore/sql_builder.dart';

import '../tool/util.dart';

enum EntityState {
  None,
  New,
  Modified,
  Deleted,
}

abstract class DataStore {
  ///建表和索引
  dynamic create(String tableName, List<String> fields,
      [List<String>? indexFields]);

  dynamic run(Sql sql);

  execute(List<Sql> sqls);

  Future<Object?> get(String table, dynamic id);

  Future<List<Map>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  Future<Map<String, Object>> findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  /// 查询单条记录
  /// @param {*} tableName
  /// @param {*} fields
  /// @param {*} condition
  Future<Map?> findOne(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  /// 插入一条记录,假设entity时一个有id属性的Object，或者Map
  /// @param {*} tableName
  /// @param {*} entity
  Future<int> insert(String table, dynamic entity);

  /// 删除记录
  /// @param {*} tableName
  /// @param {*} condition
  Future<int> delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs});

  /// 更新记录
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} condition
  Future<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  Future<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  /// 在一个事务里面执行多个操作（insert,update,devare)
  /// operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
  /// @param {*} operators
  Future<Object?> transaction(List<Map<String, dynamic>> operators);
}
