import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/conference.dart';
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
  late CommonDatabase db;

  open({String name = dbname}) async {
    db = await sqlite3_open.openSqlite3(name: name);
    //开发调试阶段，每次都重建数据库表
    //db.userVersion = 0;
    await init(db);
  }

  init(CommonDatabase db) async {
    int userVersion = 0;
    try {
      userVersion = db.userVersion;
    } catch (e) {
      print('sqlite3 db get userVersion failure:$e');
    }

    /// 删除新版本中有变化的表，重建
    String? existAppVersion = await localSharedPreferences.get('appVersion');
    if (existAppVersion != null) {
      if (existAppVersion.compareTo(appVersion) < 0) {
        drop(conferenceService.tableName);
      }
    }

    for (GeneralBaseService service in ServiceLocator.services.values) {
      try {
        create(service.tableName, service.fields,
            indexFields: service.indexFields);
      } catch (e) {
        print('sqlite3 init create table exception:$e');
      }
    }
    try {
      db.userVersion = 1;
    } catch (e) {
      print('sqlite3 db set userVersion 1 failure:$e');
    }
    for (GeneralBaseService service in ServiceLocator.services.values) {
      service.dataStore = this;
    }
  }

  reset() {
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// 关闭数据库
  close() {
    db.dispose();
  }

  File? backup() {
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      return file.copySync('${appDataProvider.sqlite3Path}.bak');
    }
    return null;
  }

  restore() {
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      close();
      file.renameSync('${appDataProvider.sqlite3Path}.ret');
    }
    file = File('${appDataProvider.sqlite3Path}.bak');
    if (file.existsSync()) {
      file.renameSync(appDataProvider.sqlite3Path);
    }
    open();
  }

  /// 删除数据库
  /// @param {*} options
  remove({name = dbname, location = 'default'}) {}

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
      logger.i('execute sql:${sql.clause}');
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
      {List<String>? indexFields, bool drop = false}) {
    if (drop) {
      String clause = sqlBuilder.drop(tableName);
      run(Sql(clause));
    }
    List<String> clauses = sqlBuilder.create(tableName, fields, indexFields);
    for (var query in clauses) {
      run(Sql(query));
    }
    return null;
  }

  /// 删除表
  drop(String tableName) {
    var query = sqlBuilder.drop(tableName);

    return run(Sql(query));
  }

  @override
  Object? get(String table, dynamic id) {
    return findOne(table, where: 'id=?', whereArgs: [id]);
  }

  @override
  List<Map> find(String table,
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
    var results = db.select(clause, whereArgs);
    // logger.i('execute sql:$clause');
    // logger.i('execute sql params:$whereArgs');

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
    var totalResults = db.select(clause, whereArgs);
    // logger.i('execute sql:$clause');
    // logger.i('execute sql params:$whereArgs');
    var rowsNumber = TypeUtil.firstIntValue(totalResults);
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
  Map? findOne(String table,
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
    int result = db.getUpdatedRows();

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
    int result = db.getUpdatedRows();

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
    var results = db.getUpdatedRows();
    return results;
  }
}

final Sqlite3 sqlite3 = Sqlite3();
