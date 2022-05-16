import 'dart:async';
import 'dart:convert';
import 'package:idb_shim/idb.dart';
import 'package:path/path.dart';
import 'package:idb_shim/idb_browser.dart';

import 'datastore.dart';

/**
 * 适用于移动手机（无数据限制），electron和chrome浏览器的sqlite3的数据库（50M数据限制）
 */
class IndexedDb extends DataStore {
  late Database db;
  late String path;

  /**
   * 创建或者打开数据库
   * @param {*} options
   */
  open([String name = 'colla_chat.db']) async {
    IdbFactory? idbFactory = getIdbFactory();
    if (idbFactory != null) {
      db = await idbFactory.open(name, version: 1,
          onUpgradeNeeded: (VersionChangeEvent event) {
        Database db = event.database;
        // create the store
        for (var dataStoreDef in this.dataStoreDefs!) {
          this.create(dataStoreDef.tableName, dataStoreDef.fields!,
              dataStoreDef.indexFields);
        }
      });
    }
    return this;
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

  /**
   * 建表
   * @param {*} tableName
   * @param {*} fields
   */
  @override
  dynamic create(String tableName, List<String> fields,
      [List<String>? indexFields]) {
    var store =
        db.createObjectStore(tableName, autoIncrement: true, keyPath: 'id');
    for (var indexField in indexFields!) {
      store.createIndex(indexField, indexField);
    }

    return store;
  }

  /**
   * 删除表
   * @param {*} tableName
   */
  drop(String tableName) {
    var query = sqlBuilder.drop(tableName);

    return run(Sql(query));
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
  Future<List<Object?>> find(String table,
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
        var results = index.getAll(keyRange['keyRange'], limit);
        await txn.completed;

        return results;
      }
    }
    var results = store.getAll();
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

    return 1;
  }

  /**
   * 删除记录
   * @param {*} tableName
   * @param {*} condition
   */
  @override
  Future<int> delete(String table,
      {dynamic entity, String? where, List<Object?>? whereArgs}) async {
    if (entity != null) {
      var json = jsonEncode(entity);
      entity = jsonDecode(json);
      var id = entity['id'];
      if (id != null) {
        var txn = db.transaction(table, "readwrite");
        var store = txn.objectStore(table);
        var key = await store.delete(id);
        await txn.completed;

        return 1;
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
      {String? where, List<Object?>? whereArgs}) async {
    var json = jsonEncode(entity);
    entity = jsonDecode(json);
    var id = entity['id'];
    if (id != null) {
      var txn = db.transaction(table, "readwrite");
      var store = txn.objectStore(table);
      var key = await store.put(entity, id);
      await txn.completed;
      return 1;
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
    this.open();
    var sqls = <Sql>[];
    sqls.add(Sql('DROP TABLE IF EXISTS test_table'));
    sqls.add(Sql(
        'CREATE TABLE IF NOT EXISTS test_table (id integer primary key, data text, data_num integer)'));
    this.execute(sqls);
    this.insert('test_table', {'id': 1, 'data': 'hello1', 'data_num': 1234561});
    this.insert('test_table', {'id': 2, 'data': 'hello2', 'data_num': 1234562});
    var results =
        await this.findOne('test_table', where: 'id=?', whereArgs: [1]);
    this.update('test_table', {'data': 'hello-update', 'data_num': 12345678},
        where: 'id=?', whereArgs: [1]);
    this.delete('test_table', where: 'id=?', whereArgs: [1]);
  }
}

var indexeddb = IndexedDb().open();
