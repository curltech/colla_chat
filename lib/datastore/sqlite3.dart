import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/create_service.dart';
import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/type_util.dart';
import 'package:sqlite3/common.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as sqlite3_open;

/// 适用于移动手机（无数据限制），desktop和chrome浏览器的sqlite3的数据库（50M数据限制）
class Sqlite3 extends DataStore {
  CommonDatabase? db;
  final String dbPath;

  Sqlite3(this.dbPath);

  @override
  Future<bool> open() async {
    for (int i = 0; i < 3; i++) {
      try {
        db = await sqlite3_open.openSqlite3(path: dbPath);
        break;
      } catch (e) {
        await Future.delayed(Duration(milliseconds: (i + 1) * 100));
      }
    }

    return db != null;
  }

  Future<bool> init() async {
    if (db == null) {
      return false;
    }
    int userVersion = 0;
    try {
      userVersion = db!.userVersion;
    } catch (e) {
      print('sqlite3 db get userVersion failure:$e');
    }

    await localSharedPreferences.init();

    /// 删除新版本中有变化的表，重建
    String? existAppVersion = await localSharedPreferences.get('appVersion');
    print('current appVersion:$existAppVersion');
    for (var createServices in createServices) {
      drop(createServices.tableName);
    }
    await localSharedPreferences.save('appVersion', appVersion);
    print('new appVersion:$appVersion');

    for (GeneralBaseService service in ServiceLocator.services.values) {
      try {
        create(service.tableName, service.fields,
            uniqueFields: service.uniqueFields,
            indexFields: service.indexFields);
      } catch (e) {
        print('sqlite3 init create table exception:$e');
      }
    }
    try {
      db!.userVersion = 1;
    } catch (e) {
      print('sqlite3 db set userVersion 1 failure:$e');
    }
    for (GeneralBaseService service in ServiceLocator.services.values) {
      service.dataStore = this;
    }

    return true;
  }

  reset() {
    File file = File(dbPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// 关闭数据库
  close() {
    if (db != null) {
      db!.dispose();
      db == null;
    }
  }

  File? backup() {
    File file = File(dbPath);
    if (file.existsSync()) {
      return file.copySync('$dbPath.bak');
    }
    return null;
  }

  restore() async {
    File file = File(dbPath);
    if (file.existsSync()) {
      close();
      file.renameSync('$dbPath.ret');
    }
    file = File('$dbPath.bak');
    if (file.existsSync()) {
      file.renameSync(dbPath);
    }
    await open();
    await init();
  }

  /// 删除数据库
  /// @param {*} options
  remove() {}

  /// 批量执行sql，参数是二维数组
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic execute(List<Sql> sqls) {
    for (var sql in sqls) {
      run(sql);
      logger.i('execute sql:${sql.clause}');
    }
  }

  /// 执行单条sql
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic run(Sql sql) {
    try {
      if (sql.params != null) {
        var params = sql.params;
        db!.execute(sql.clause, params!);
      } else {
        db!.execute(sql.clause);
      }
    } catch (e) {
      logger.e('sqlite3 run sql:$sql failure:\n$e');
      rethrow;
    }

    return null;
  }

  /// 建表和索引
  @override
  dynamic create(String tableName, List<String> fields,
      {List<String>? uniqueFields,
      List<String>? indexFields,
      bool drop = false}) {
    if (drop) {
      String clause = sqlBuilder.drop(tableName);
      run(Sql(clause));
    }
    List<String> clauses = sqlBuilder.create(tableName, fields,
        uniqueFields: uniqueFields, indexFields: indexFields);
    for (var query in clauses) {
      run(Sql(query));
    }
    return null;
  }

  /// 删除表
  dynamic drop(String tableName) {
    var query = sqlBuilder.drop(tableName);

    return run(Sql(query));
  }

  /// 查询执行
  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    try {
      return db!.select(sql, parameters);
    } catch (e) {
      logger.e('sqlite3 select sql:$sql failure:\n$e');
      rethrow;
    }
  }

  vacuum() {
    try {
      db!.execute('VACUUM');
    } catch (e) {
      logger.e('sqlite3 execute sql:VACUUM failure:\n$e');
      rethrow;
    }
  }

  @override
  Object? get(String table, dynamic id) {
    return findOne(table, where: 'id=?', whereArgs: [id]);
  }

  @override
  List<Map<String, dynamic>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    var clause = sqlBuilder.select(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    whereArgs ??= [];
    ResultSet results = select(clause, whereArgs);

    return results;
  }

  @override
  Pagination findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int limit = defaultLimit,
      int offset = defaultOffset}) {
    var clause = sqlBuilder.select(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
    );
    clause = 'select count(*) from ($clause)';
    whereArgs = whereArgs ?? [];
    ResultSet totalResults = select(clause, whereArgs);
    int rowsNumber = TypeUtil.firstIntValue(totalResults);
    var results = find(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);

    Pagination page = Pagination(
        data: results, count: rowsNumber, offset: offset, limit: limit);

    return page;
  }

  /// 查询单条记录
  /// @param {*} tableName
  /// @param {*} fields
  /// @param {*} condition
  @override
  Map<String, dynamic>? findOne(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    var results = find(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    if (results.isNotEmpty) {
      return results[0];
    }

    return null;
  }

  /// 插入一条记录
  /// @param {*} tableName
  /// @param {*} entity
  @override
  int insert(String table, dynamic entity) {
    Map<String, dynamic> map = JsonUtil.toJson(entity) as Map<String, dynamic>;
    Sql sql = sqlBuilder.insert(table, map);
    run(sql);
    int key = db!.lastInsertRowId;
    Object? id = EntityUtil.getId(entity);
    if (id == null) {
      EntityUtil.setId(entity, key);
    }

    return key;
  }

  /// 删除记录
  /// @param {*} tableName
  /// @param {*} condition
  @override
  int delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs}) {
    if (entity != null) {
      Map<String, dynamic> map =
          JsonUtil.toJson(entity) as Map<String, dynamic>;
      var id = EntityUtil.getId(map);
      if (id != null) {
        where = 'id=?';
        whereArgs = [id];
      } else if (map.isNotEmpty) {
        where ??= '1=1';
        whereArgs ??= [];
        for (var entry in map.entries) {
          where = '$where and ${entry.key} = ?';
          whereArgs.add(entry.value);
        }
      }
    }

    Sql sql = sqlBuilder.delete(table, where!, whereArgs);

    run(sql);
    int result = db!.updatedRows;

    return result;
  }

  /// 更新记录。根据entity的id字段作为条件，其他字段作为更新的值
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} condition
  @override
  int update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) {
    Map<String, dynamic> map = JsonUtil.toJson(entity) as Map<String, dynamic>;
    var id = EntityUtil.getId(map);
    if (id != null) {
      where = 'id=?';
      whereArgs = [id];
    }
    Sql sql = sqlBuilder.update(table, map, where!, whereArgs);

    run(sql);
    int result = db!.updatedRows;

    return result;
  }

  @override
  int upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) {
    Map<String, dynamic> map = JsonUtil.toJson(entity) as Map<String, dynamic>;
    var id = EntityUtil.getId(map);
    if (id != null) {
      return update(table, entity);
    } else {
      return insert(table, entity);
    }
  }

  /// 在一个事务里面执行多个操作（insert,update,devare)
  /// operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
  /// @param {*} operators
  @override
  Object? transaction(List<Map<String, dynamic>> operators) {
    for (var i = 0; i < operators.length; ++i) {
      var operator = operators[i];
      var table = operator['table'];
      var entity = operator['entity'];
      var where = operator['where'];
      var whereArgs = operator['whereArgs'];
      if (entity != null) {
        var json = jsonEncode(entity);
        entity = jsonDecode(json);
        if (entity is List) {
          for (var e in entity) {
            var json = jsonEncode(e);
            var m = jsonDecode(json);
            var state = m['state'];
            if (EntityState.insert == state) {
              m.remove('state');
              insert(table, m);
            } else if (EntityState.update == state) {
              m.remove('state');
              update(table, m, where: where, whereArgs: whereArgs);
            } else if (EntityState.delete == state) {
              m.remove('state');
              delete(table, where: where, whereArgs: whereArgs);
            }
          }
        } else {
          var state = entity['state'];
          if (EntityState.insert == state) {
            entity.remove('state');
            insert(table, entity);
          } else if (EntityState.update == state) {
            entity.remove('state');
            update(table, entity, where: where, whereArgs: whereArgs);
          } else if (EntityState.delete == state) {
            entity.remove('state');
            delete(table, where: where, whereArgs: whereArgs);
          }
        }
      }
    }
    var results = db!.updatedRows;
    return results;
  }
}

final Sqlite3 sqlite3 = Sqlite3(appDataProvider.sqlite3Path);
