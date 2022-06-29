import 'dart:async';
import 'dart:convert';

import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../service/base.dart';
import '../service/servicelocator.dart';
import 'datastore.dart';

/// 适用于移动手机（无数据限制），electron和chrome浏览器的sqlite3的数据库（50M数据限制）
class Sqflite extends DataStore {
  static Sqflite instance = Sqflite();
  static bool initStatus = false;
  late Database db;
  late String path;

  /// 打开数据库，创建所有的表和索引
  static Future<Sqflite> getInstance({String name = 'colla_chat.db'}) async {
    if (!initStatus) {
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, name);
      instance.db = await openDatabase(
        path,
        version: 1,
      );
      for (BaseService service in ServiceLocator.services.values) {
        instance.create(service.tableName, service.fields, service.indexFields);
        service.dataStore = instance;
      }
      initStatus = true;
    }
    return instance;
  }

  /// 关闭数据库
  close() {
    db.close();
  }

  /// 删除数据库
  /// @param {*} options
  remove({name = 'colla_chat.db', location = 'default'}) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, name);
    deleteDatabase(path);
  }

  /// 批量执行sql，参数是二维数组
  /// @param {*} sqls
  /// @param {*} params
  @override
  execute(List<Sql> sqls) {
    db.transaction((txn) async {
      for (var sql in sqls) {
        await txn.execute(sql.clause, sql.params);
      }
    });
  }

  /// 执行单条sql
  /// @param {*} sqls
  /// @param {*} params
  @override
  dynamic run(Sql sql) {
    return db.execute(sql.clause, sql.params);
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
    return await db.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  @override
  Future<Page> findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int limit = 10,
      int offset = 0}) async {
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
    var totalResults = await db.rawQuery(clause, whereArgs);
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

    Page page = Page(data: results, total: total, offset: offset, limit: limit);

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
    int key = await db.insert(table, entity);
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

    int result = await db.delete(table, where: where, whereArgs: whereArgs);

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
    int result =
        await db.update(table, entity, where: where, whereArgs: whereArgs);
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
    var results = await db.transaction((txn) async {
      var batch = txn.batch();
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
                batch.insert(table, m);
              } else if (EntityState.Modified == state) {
                m.remove('state');
                batch.update(table, m, where: where, whereArgs: whereArgs);
              } else if (EntityState.Deleted == state) {
                m.remove('state');
                batch.delete(table, where: where, whereArgs: whereArgs);
              }
            }
          } else {
            var state = entity['state'];
            if (EntityState.New == state) {
              entity.remove('state');
              batch.insert(table, entity);
            } else if (EntityState.Modified == state) {
              entity.remove('state');
              batch.update(table, entity, where: where, whereArgs: whereArgs);
            } else if (EntityState.Deleted == state) {
              entity.remove('state');
              batch.delete(table, where: where, whereArgs: whereArgs);
            }
          }
        }
      }
      var results = await batch.commit();
      return results;
    });

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
