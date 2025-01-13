import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/sql_builder.dart' as sql_builder;
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:postgres/postgres.dart';

/// 适用于移动手机（无数据限制），desktop和chrome浏览器的sqlite3的数据库（50M数据限制）
class Postgres extends DataStore {
  Connection? db;
  late String host;
  late int port;
  late String user;
  String? password;
  late String database;

  Postgres({
    this.host = 'localhost',
    this.port = 5432,
    this.user = 'postgres',
    required String password,
    this.database = 'postgres',
  });

  @override
  Future<bool> open() async {
    db = await Connection.open(Endpoint(
      host: 'localhost',
      port: 5432,
      database: database,
      username: user,
      password: password,
    ));

    return db != null;
  }

  Future<bool> init() async {
    if (db == null) {
      return false;
    }
    int userVersion = 0;
    try {
      // userVersion = db!.userVersion;
    } catch (e) {
      print('sqlite3 db get userVersion failure:$e');
    }

    await localSharedPreferences.init();

    /// 删除新版本中有变化的表，重建
    String? existAppVersion = await localSharedPreferences.get('appVersion');
    print('current appVersion:$existAppVersion');
    if (existAppVersion != null) {
      if (existAppVersion.compareTo(appVersion) < 0) {
        //drop(conferenceService.tableName);
      }
    }
    // drop(myselfPeerService.tableName);
    // drop(conferenceService.tableName);
    // drop(peerEndpointService.tableName);
    // drop(peerProfileService.tableName);
    await localSharedPreferences.save('appVersion', appVersion);
    print('new appVersion:$appVersion');

    for (GeneralBaseService service in ServiceLocator.services.values) {
      try {
        create(service.tableName, service.fields,
            indexFields: service.indexFields);
      } catch (e) {
        print('sqlite3 init create table exception:$e');
      }
    }
    try {
      // db!.userVersion = 1;
    } catch (e) {
      print('sqlite3 db set userVersion 1 failure:$e');
    }
    for (GeneralBaseService service in ServiceLocator.services.values) {
      service.dataStore = this;
    }

    return true;
  }

  reset() {
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// 关闭数据库
  close() async {
    if (db != null) {
      await db!.close();
      db == null;
    }
  }

  File? backup() {
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      return file.copySync('${appDataProvider.sqlite3Path}.bak');
    }
    return null;
  }

  restore() async {
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      close();
      file.renameSync('${appDataProvider.sqlite3Path}.ret');
    }
    file = File('${appDataProvider.sqlite3Path}.bak');
    if (file.existsSync()) {
      file.renameSync(appDataProvider.sqlite3Path);
    }
    // await open();
    await init();
  }

  /// 删除数据库
  /// @param {*} options
  remove() {}

  /// 批量执行sql，参数是二维数组
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic execute(List<sql_builder.Sql> sqls) async {
    for (var sql in sqls) {
      logger.i('execute sql:${sql.clause}');
      if (sql.params != null) {
        var params = sql.params;
        await db!.execute(sql.clause, parameters: params!);
      } else {
        await db!.execute(sql.clause);
      }
    }
  }

  /// 执行单条sql
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic run(sql_builder.Sql sql) async {
    if (sql.params != null) {
      var params = sql.params;
      return await db!.execute(sql.clause, parameters: params!);
    } else {
      return await db!.execute(sql.clause);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> select(String sql,
      [List<Object?> parameters = const []]) async {
    Result result = await db!.execute(sql, parameters: parameters);
    List<Map<String, dynamic>> maps = [];
    for (var r in result) {
      maps.add(r.toColumnMap());
    }

    return maps;
  }

  /// 建表和索引
  @override
  dynamic create(String tableName, List<String> fields,
      {List<String>? indexFields, bool drop = false}) async {
    if (drop) {
      String clause = sql_builder.sqlBuilder.drop(tableName);
      await run(sql_builder.Sql(clause));
    }
    List<String> clauses =
        sql_builder.sqlBuilder.create(tableName, fields, indexFields);
    for (var query in clauses) {
      await run(sql_builder.Sql(query));
    }
    return null;
  }

  /// 删除表
  dynamic drop(String tableName) async {
    var query = sql_builder.sqlBuilder.drop(tableName);

    return await run(sql_builder.Sql(query));
  }

  @override
  Future<Object?> get(String table, dynamic id) async {
    return await findOne(table, where: 'id=?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    var clause = sql_builder.sqlBuilder.select(table,
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
    Result result = await db!.execute(clause, parameters: whereArgs);

    List<Map<String, dynamic>> maps = [];
    for (var r in result) {
      maps.add(r.toColumnMap());
    }

    return maps;
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
    var clause = sql_builder.sqlBuilder.select(
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
    var totalResults = await db!.execute(clause, parameters: whereArgs);
    var rowsNumber = totalResults.affectedRows;
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
        data: results, count: rowsNumber, offset: offset, limit: limit);

    return page;
  }

  /// 查询单条记录
  /// @param {*} tableName
  /// @param {*} fields
  /// @param {*} condition
  @override
  Future<Map<String, dynamic>?> findOne(String table,
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
    sql_builder.Sql sql = sql_builder.sqlBuilder.insert(table, map);
    Result result = await run(sql);

    return result.affectedRows;
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
      } else if (map.isNotEmpty) {
        where ??= '1=1';
        whereArgs ??= [];
        for (var entry in map.entries) {
          where = '$where and ${entry.key} = ?';
          whereArgs.add(entry.value);
        }
      }
    }

    sql_builder.Sql sql =
        sql_builder.sqlBuilder.delete(table, where!, whereArgs);

    Result result = await run(sql);

    return result.affectedRows;
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
    sql_builder.Sql sql =
        sql_builder.sqlBuilder.update(table, map, where!, whereArgs);

    Result result = await run(sql);

    return result.affectedRows;
  }

  @override
  Future<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) async {
    Map<String, dynamic> map = JsonUtil.toJson(entity) as Map<String, dynamic>;
    var id = EntityUtil.getId(map);
    if (id != null) {
      return await update(table, entity);
    } else {
      return await insert(table, entity);
    }
  }

  /// 在一个事务里面执行多个操作（insert,update,devare)
  /// operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
  /// @param {*} operators
  @override
  Future<Object?> transaction(List<Map<String, dynamic>> operators) async {
    Object? result;
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
              result = await insert(table, m);
            } else if (EntityState.update == state) {
              m.remove('state');
              result =
                  await update(table, m, where: where, whereArgs: whereArgs);
            } else if (EntityState.delete == state) {
              m.remove('state');
              result = await delete(table, where: where, whereArgs: whereArgs);
            }
          }
        } else {
          var state = entity['state'];
          if (EntityState.insert == state) {
            entity.remove('state');
            result = await insert(table, entity);
          } else if (EntityState.update == state) {
            entity.remove('state');
            result =
                await update(table, entity, where: where, whereArgs: whereArgs);
          } else if (EntityState.delete == state) {
            entity.remove('state');
            result = await delete(table, where: where, whereArgs: whereArgs);
          }
        }
      }
    }

    return result;
  }
}
