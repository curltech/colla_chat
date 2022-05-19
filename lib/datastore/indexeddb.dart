import 'dart:async';
import 'dart:convert';
import 'package:colla_chat/datastore/base.dart';
import 'package:idb_shim/idb.dart';
import 'package:path/path.dart';
import 'package:idb_shim/idb_browser.dart';

import 'datastore.dart';

/**
 * 适用于移动手机（无数据限制），electron和chrome浏览器的sqlite3的数据库（50M数据限制）
 */
class IndexedDb extends DataStore {
  static IndexedDb instance = IndexedDb();
  static bool initStatus = false;

  late Database db;
  late String path;

  ///打开数据库，创建所有的表和索引
  static Future<IndexedDb> getInstance({String name = 'colla_chat.db'}) async {
    if (!initStatus) {
      IdbFactory? idbFactory = getIdbFactory();
      if (idbFactory != null) {
        instance.db = await idbFactory.open(name, version: 1,
            onUpgradeNeeded: (VersionChangeEvent event) {
          Database db = event.database;
          instance.db = db;
          for (BaseService service in ServiceLocator.services.values) {
            instance.create(
                service.tableName, service.fields, service.indexFields);
            service.dataStore = instance;
          }
        });
      }
      initStatus = true;
    }
    return instance;
  }

  /**
   * 关闭数据库
   */
  close() {
    db.close();
  }

  /**
   * 删除数据库
   * @param {*} options
   */
  remove({name = 'colla_chat.db', location = 'default'}) async {}

  /**
   * 批量执行sql，参数是二维数组
   * @param {*} sqls
   * @param {*} params
   */
  @override
  execute(List<Sql> sqls) {}

  /**
   * 执行单条sql
   * @param {*} sqls
   * @param {*} params
   */
  @override
  dynamic run(Sql sql) {}

  /// 建表和索引
  @override
  dynamic create(String tableName, List<String> fields,
      [List<String>? indexFields]) {
    var store =
        db.createObjectStore(tableName, autoIncrement: true, keyPath: 'id');
    if (indexFields != null && indexFields.isNotEmpty) {
      for (var indexField in indexFields) {
        store.createIndex(indexField, indexField);
      }
    }

    return store;
  }

  /**
   * 删除表
   * @param {*} tableName
   */
  drop(String tableName) async {
    var txn = db.transaction(tableName, "readonly");
    var store = txn.objectStore(tableName);
    await store.clear();
    await txn.completed;
  }

  @override
  Future<Object?> get(String table, dynamic id) async {
    var txn = db.transaction(table, "readonly");
    var store = txn.objectStore(table);
    var o = await store.getObject(id);
    await txn.completed;

    return o;
  }

  Map<String, dynamic>? _buildKeyRange(String where, List<Object> whereArgs) {
    var tokens = where.split(' ');
    String key = tokens[0];
    late KeyRange keyRange;
    if (tokens.length == 3) {
      var op = tokens[1];
      switch (op) {
        case '>=':
          keyRange = KeyRange.lowerBound(whereArgs[0], true);
          break;
        case '<=':
          keyRange = KeyRange.upperBound(whereArgs[0], true);
          break;
        case '>':
          keyRange = KeyRange.lowerBound(whereArgs[0], false);
          break;
        case '<':
          keyRange = KeyRange.upperBound(whereArgs[0], false);
          break;
        case '=':
          keyRange = KeyRange.only(whereArgs[0]);
          break;
        default:
      }
    } else if (tokens.length == 5) {
      key = tokens[0];
      var lowerOpen = false;
      var upperOpen = false;
      var op1 = tokens[1];
      if (op1 == '>=') {
        lowerOpen = true;
      }
      var op2 = tokens[3];
      if (op2 == '<=') {
        upperOpen = true;
      }
      keyRange =
          KeyRange.bound(whereArgs[0], whereArgs[1], lowerOpen, upperOpen);
    }
    return {'key': key, 'keyRange': keyRange};
  }

  @override
  Future<List<Object>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    var txn = db.transaction(table, "readonly");
    var store = txn.objectStore(table);
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      var keyRange = _buildKeyRange(where, whereArgs);
      if (keyRange != null) {
        var indexName = keyRange['key'];
        List<Object> results = [];
        if (indexName == 'id') {
          KeyRange range = keyRange['keyRange'] as KeyRange;
          Object? id = range.lower;
          if (id != null) {
            Object? result = await store.getObject(id);
            if (result != null) {
              results.add(result);
            }
          }
        } else {
          var index = store.index(indexName);
          results = await index.getAll(keyRange['keyRange'], limit);
        }
        await txn.completed;

        return results;
      }
    }
    var results = await store.getAll();
    await txn.completed;
    return results;
  }

  @override
  Future<Map<String, Object?>> findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    var txn = db.transaction(table, "readonly");
    var store = txn.objectStore(table);
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      var keyRange = _buildKeyRange(where, whereArgs);
      if (keyRange != null) {
        var index = store.index(keyRange['key']);
        var total = index.count(keyRange['keyRange']);
        var results = index.getAll(keyRange['keyRange'], limit);
        await txn.completed;
        var page = {'data': results, 'total': total};

        return page;
      }
    }
    var results = store.getAll();
    var total = store.count();
    await txn.completed;
    var page = {'data': results, 'total': total};

    return page;
  }

  /**
   * 查询单条记录
   * @param {*} tableName
   * @param {*} fields
   * @param {*} condition
   */
  @override
  Future<Object?> findOne(String table,
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

  /**
   * 插入一条记录
   * @param {*} tableName
   * @param {*} entity
   */
  @override
  Future<int> insert(String table, dynamic entity) async {
    var json = jsonEncode(entity);
    entity = jsonDecode(json);

    var txn = db.transaction(table, "readwrite");
    var store = txn.objectStore(table);
    var key = await store.add(entity);
    await txn.completed;
    entity['id'] = key;

    return key as int;
  }

  /**
   * 删除记录
   * @param {*} tableName
   * @param {*} condition
   */
  @override
  Future<int> delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs}) async {
    if (entity != null) {
      var json = jsonEncode(entity);
      entity = jsonDecode(json);
      var id = entity['id'];
      if (id != null) {
        var txn = db.transaction(table, "readwrite");
        var store = txn.objectStore(table);
        var key = await store.delete(id);
        await txn.completed;

        return id;
      }
    }

    return 0;
  }

  /**
   * 更新记录
   * @param {*} tableName
   * @param {*} entity
   * @param {*} condition
   */
  @override
  Future<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs}) async {
    var json = jsonEncode(entity);
    entity = jsonDecode(json);
    var id = entity['id'];
    if (id != null) {
      var txn = db.transaction(table, "readwrite");
      var store = txn.objectStore(table);
      var key = await store.put(entity);
      await txn.completed;
      return key as int;
    }
    return 0;
  }

  /**
   * 在一个事务里面执行多个操作（insert,update,devare)
   * operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
   * @param {*} operators
   */
  @override
  Future<Object?> transaction(List<Map<String, dynamic>> operators) async {
    for (var i = 0; i < operators.length; ++i) {
      var operator = operators[i];
      var table = operator['table'];
      var txn = db.transaction(table, "readwrite");
      var store = txn.objectStore(table);
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
            var id = m['id'];
            var state = m['state'];
            if (EntityState.New == state) {
              m.remove('state');
              store.add(m, id);
            } else if (EntityState.Modified == state) {
              m.remove('state');
              store.put(m, id);
            } else if (EntityState.Deleted == state) {
              m.remove('state');
              store.delete(id);
            }
          }
        } else {
          var id = entity['id'];
          var state = entity['state'];
          if (EntityState.New == state) {
            entity.remove('state');
            store.add(entity, id);
          } else if (EntityState.Modified == state) {
            entity.remove('state');
            store.put(entity, id);
          } else if (EntityState.Deleted == state) {
            entity.remove('state');
            store.delete(id);
          }
        }
      }
      await txn.completed;
    }

    return null;
  }

  test() async {
    await insert('stk_account', {'data': 'hello1', 'data_num': 1234561});
    await insert('stk_account', {'data': 'hello2', 'data_num': 1234562});
    var results = await findOne('stk_account', where: 'id = ?', whereArgs: [1]);
    await update('stk_account',
        {'id': 1, 'data': 'hello-update1', 'data_num': 12345678});
    await delete('stk_account', entity: {'id': 2});
  }
}
