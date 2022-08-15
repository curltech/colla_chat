import 'dart:async';
import 'dart:convert';

import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:sqlite3/common.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as sqlite3_open;
import '../constant/base.dart';
import '../service/general_base.dart';
import '../service/servicelocator.dart';
import 'datastore.dart';

/// 适用于移动手机（无数据限制），desktop和chrome浏览器的sqlite3的数据库（50M数据限制）
class Sqlite3 extends DataStore {
  static Sqlite3 instance = Sqlite3();
  static bool initStatus = false;
  late CommonDatabase db;
  late String path;

  /// 打开数据库，创建所有的表和索引
  static Future<Sqlite3> getInstance({String name = dbname}) async {
    if (!initStatus) {
      await instance.open();
      initStatus = true;
    }
    return instance;
  }

  open({String name = dbname}) async {
    db = await sqlite3_open.openSqlite3(name: name);
    //开发调试阶段，每次都重建数据库表
    //db.userVersion = 0;
    await init(db);
    var platformParams = PlatformParams.instance;
    if (platformParams.web) {
    } else {}
  }

  init(CommonDatabase db) {
    if (db.userVersion == 0) {
      for (GeneralBaseService service in ServiceLocator.services.values) {
        instance.create(service.tableName, service.fields, service.indexFields);
      }
      db.userVersion = 1;
    }
    for (GeneralBaseService service in ServiceLocator.services.values) {
      service.dataStore = instance;
    }
  }

  reset() {
    db.userVersion = 0;
  }

  /// 关闭数据库
  close() {
    db.dispose();
  }

  /// 删除数据库
  /// @param {*} options
  remove({name = dbname, location = 'default'}) async {
    if (path != null) {}
  }

  /// 批量执行sql，参数是二维数组
  /// @param {*} sqls
  /// @param {*} params
  @override
  execute(List<Sql> sqls) {
    for (var sql in sqls) {
      if (sql.params != null) {
        var params = sql.params;
        db.execute(sql.clause, params!);
      } else {
        db.execute(sql.clause);
      }
      // logger.i('execute sql:${sql.clause}');
      // logger.i('execute sql params:${sql.params}');
    }
  }

  /// 执行单条sql
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic run(Sql sql) {
    if (sql.params != null) {
      var params = sql.params;
      db.execute(sql.clause, params!);
    } else {
      db.execute(sql.clause);
    }
    // logger.i('execute sql:${sql.clause}');
    // logger.i('execute sql params:${sql.params}');

    return null;
  }

  /// 建表和索引
  @override
  dynamic create(String tableName, List<String> fields,
      [List<String>? indexFields]) {
    String clause = sqlBuilder.drop(tableName);
    run(Sql(clause));
    List<String> clauses = sqlBuilder.create(tableName, fields, indexFields);
    for (var query in clauses) {
      run(Sql(query));
    }
    return null;
  }

  /// 删除表
  /// @param {*} tableName
  drop(String tableName) {
    var query = sqlBuilder.drop(tableName);

    return run(Sql(query));
  }

  @override
  Future<Object?> get(String table, dynamic id) {
    return findOne(table, where: 'id=?', whereArgs: [id]);
  }

  @override
  Future<List<Map>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
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
    var results = db.select(clause, whereArgs);
    // logger.i('execute sql:$clause');
    // logger.i('execute sql params:$whereArgs');

    return results;
  }

  @override
  Future<Pagination> findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int limit = defaultLimit,
      int offset = defaultOffset}) async {
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
    var totalResults = db.select(clause, whereArgs);
    // logger.i('execute sql:$clause');
    // logger.i('execute sql params:$whereArgs');
    var rowsNumber = TypeUtil.firstIntValue(totalResults);
    var results = await find(table,
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
        data: results,
        rowsNumber: rowsNumber,
        offset: offset,
        rowsPerPage: limit);

    return page;
  }

  /// 查询单条记录
  /// @param {*} tableName
  /// @param {*} fields
  /// @param {*} condition
  @override
  Future<Map?> findOne(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    var results = await find(table,
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
  Future<int> insert(String table, dynamic entity) async {
    Map<String, dynamic> map = JsonUtil.toJson(entity) as Map<String, dynamic>;
    Sql sql = sqlBuilder.insert(table, map);
    await run(sql);
    int key = db.lastInsertRowId;
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
  Future<int> delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs}) async {
    if (entity != null) {
      Map<String, dynamic> map =
          JsonUtil.toJson(entity) as Map<String, dynamic>;
      var id = EntityUtil.getId(map);
      if (id != null) {
        where = 'id=?';
        whereArgs = [id];
      }
    }

    Sql sql = sqlBuilder.delete(table, where!, whereArgs);

    await run(sql);
    int result = db.getUpdatedRows();

    return result;
  }

  /// 更新记录。根据entity的id字段作为条件，其他字段作为更新的值
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} condition
  @override
  Future<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) async {
    Map<String, dynamic> map = JsonUtil.toJson(entity) as Map<String, dynamic>;
    var id = EntityUtil.getId(map);
    if (id != null) {
      where = 'id=?';
      whereArgs = [id];
    }
    Sql sql = sqlBuilder.update(table, map, where!, whereArgs);

    await run(sql);
    int result = db.getUpdatedRows();

    return result;
  }

  @override
  Future<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) async {
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
  Future<Object?> transaction(List<Map<String, dynamic>> operators) async {
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
          for (var e in entity as List) {
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
    var results = db.getUpdatedRows();
    return results;
  }

  test() async {
    insert('stk_account', {'id': 1, 'data': 'hello1', 'data_num': 1234561});
    insert('stk_account', {'id': 2, 'data': 'hello2', 'data_num': 1234562});
    var results = await findOne('stk_account', where: 'id=?', whereArgs: [1]);
    update('stk_account', {'data': 'hello-update', 'data_num': 12345678},
        where: 'id=?', whereArgs: [1]);
    delete('stk_account', where: 'id=?', whereArgs: [1]);
  }
}
