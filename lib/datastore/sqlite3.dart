import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/wasm.dart';

import '../app.dart';
import '../service/base.dart';
import '../service/servicelocator.dart';
import 'datastore.dart';

import 'package:http/http.dart' as http;
import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 适用于移动手机（无数据限制），desktop和chrome浏览器的sqlite3的数据库（50M数据限制）
class Sqlite3 extends DataStore {
  static Sqlite3 instance = Sqlite3();
  static bool initStatus = false;
  late CommonDatabase db;
  late String path;

  /// 打开数据库，创建所有的表和索引
  static Future<Sqlite3> getInstance({String name = 'colla_chat.db'}) async {
    if (!initStatus) {
      await instance.open();
      initStatus = true;
    }
    return instance;
  }

  open({String name = 'colla_chat.db'}) async {
    var platformParams = await PlatformParams.instance;
    if (platformParams.web) {
      //web下的创建打开数据库的方式
      final fs = await IndexedDbFileSystem.open(dbName: 'name');
      var byteData = await rootBundle.load('assets/wasm/sqlite3.wasm');
      var source = byteData.buffer.asUint8List();

      final response = await http.get(Uri.parse('sqlite3.wasm'));
      source = response.bodyBytes;

      WasmSqlite3 wasmSqlite3 =
          await WasmSqlite3.load(source, SqliteEnvironment(fileSystem: fs));
      db = wasmSqlite3.open(name);
      await init(db);
      await fs.flush();
    } else {
      /// 除了web之外的创建打开数据库的方式
      final dbFolder = await getApplicationDocumentsDirectory();
      path = p.join(dbFolder.path, name);
      db = sqlite3.open(path);
      await init(db);
    }
  }

  init(CommonDatabase db) {
    if (db.userVersion == 0) {
      for (BaseService service in ServiceLocator.services.values) {
        instance.create(service.tableName, service.fields, service.indexFields);
        service.dataStore = instance;
      }
    }
  }

  /// 关闭数据库
  close() {
    db.dispose();
  }

  /// 删除数据库
  /// @param {*} options
  remove({name = 'colla_chat.db', location = 'default'}) async {
    if (path != null) {}
  }

  /// 批量执行sql，参数是二维数组
  /// @param {*} sqls
  /// @param {*} params
  @override
  execute(List<Sql> sqls) {
    for (var sql in sqls) {
      logger.i('execute sql:${sql.clause}');
      logger.i('execute sql params:${sql.params}');
      if (sql.params != null) {
        var params = sql.params;
        db.execute(sql.clause, params!);
      } else {
        db.execute(sql.clause);
      }
    }
  }

  /// 执行单条sql
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic run(Sql sql) {
    logger.i('execute sql:${sql.clause}');
    logger.i('execute sql params:${sql.params}');
    if (sql.params != null) {
      var params = sql.params;
      return db.execute(sql.clause, params!);
    } else {
      return db.execute(sql.clause);
    }
  }

  /// 建表和索引
  @override
  dynamic create(String tableName, List<String> fields,
      [List<String>? indexFields]) {
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
    return db.select(clause, whereArgs!);
  }

  @override
  Future<Map<String, Object>> findPage(String table,
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
    clause = 'select count(*) from ($clause)';
    var totalResults = db.select(clause, whereArgs!);
    var total = TypeUtil.firstIntValue(totalResults);
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

    Map<String, Object> page = {'data': results, 'total': total};

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
    entity = JsonUtil.toMap(entity);
    Sql sql = sqlBuilder.insert(table, entity);
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
      entity = JsonUtil.toMap(entity);
      var id = EntityUtil.getId(entity);
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

  /// 更新记录
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} condition
  @override
  Future<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) async {
    entity = JsonUtil.toMap(entity);
    var id = EntityUtil.getId(entity);
    if (id != null) {
      where = 'id=?';
      whereArgs = [id];
    }
    Sql sql = sqlBuilder.update(table, entity, where!, whereArgs);

    await run(sql);
    int result = db.getUpdatedRows();

    return result;
  }

  @override
  Future<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) async {
    entity = JsonUtil.toMap(entity);
    var id = EntityUtil.getId(entity);
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
            if (EntityState.New == state) {
              m.remove('state');
              insert(table, m);
            } else if (EntityState.Modified == state) {
              m.remove('state');
              update(table, m, where: where, whereArgs: whereArgs);
            } else if (EntityState.Deleted == state) {
              m.remove('state');
              delete(table, where: where, whereArgs: whereArgs);
            }
          }
        } else {
          var state = entity['state'];
          if (EntityState.New == state) {
            entity.remove('state');
            insert(table, entity);
          } else if (EntityState.Modified == state) {
            entity.remove('state');
            update(table, entity, where: where, whereArgs: whereArgs);
          } else if (EntityState.Deleted == state) {
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
