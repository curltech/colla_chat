import 'package:colla_chat/datastore/indexeddb.dart';
import 'package:colla_chat/datastore/sqlite3.dart';

import 'datastore.dart';

enum EntityStatus {
  Draft,
  Effective,
  Expired,
  Deleted,
  Canceled,
  Checking,
  Undefined,
  Locked,
  Checked,
  Unchecked,
  Enabled,
  Disable,
  Discarded,
  Merged,
  Reversed,
}

abstract class BaseEntity {
  int? id;
  DateTime? createDate;
  DateTime? updateDate;
  String? entityId;
  String? state;
}

abstract class StatusEntity extends BaseEntity {
  String? status;
  String? statusReason;
  DateTime? statusDate;
}

/**
 * 本地sqlite3的通用访问类，所有的表访问服务都是这个类的实例
 */
abstract class BaseService {
  late String tableName;
  late DataStore dataStore;

  BaseService(String tableName, List<String> fields,
      [List<String>? indexFields]) {
    this.tableName = tableName;
    if (indexeddb.db != null) {
      dataStore = indexeddb;
    } else {
      dataStore = sqlite3;
    }
    dataStore.create(this.tableName, fields, indexFields);
  }

  Future<Object?> get(int id) {
    return dataStore.findOne(this.tableName, where: 'id=?', whereArgs: [id]);
  }

  findOne(String? where,
      {bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    return dataStore.findOne(this.tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  /**
   * 原生的查询
   * @param condition
   * @param sort
   * @param fields
   * @param from
   * @param limit
   */
  Future<List<Object?>> find(String? where,
      {bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    return dataStore.find(this.tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  /**
   * 与find的不同是返回值是带有result，from，limit，total字段的对象
   * @param condition
   * @param sort
   * @param fields
   * @param from
   * @param limit
   */
  Future<Map<String, Object?>> findPage(String? where,
      {bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    return dataStore.findPage(this.tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  /**
   * 与find的区别是condi是普通对象，采用等于条件
   * @param condi
   * @param sort
   * @param fields
   * @param from
   * @param limit
   */
  Future<List<Object?>> seek(Map<String, Object> whereBean,
      {bool? distinct,
      List<String>? columns,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    var where = '1=1';
    List<Object> whereArgs = [];
    for (var key in whereBean.keys) {
      var value = whereBean[key];
      where = where + ' and ' + key + '=?';
      whereArgs.add(value!);
    }
    return dataStore.find(this.tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  Future<int> insert(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    return dataStore.insert(this.tableName, entity);
  }

  Future<int> delete(dynamic entity) {
    return dataStore.delete(this.tableName, entity: entity);
  }

  Future<int> update(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    return dataStore.update(this.tableName, entity);
  }

  /**
   * 批量保存，根据脏标志新增，修改或者删除
   * @param entities
   * @param ignore
   * @param parent
   */
  save(List<Object> entities, [dynamic? ignore, dynamic? parent]) {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      operators.add({'table': this.tableName, 'entity': entity});
    }
    return dataStore.transaction(operators);
  }

  /**
   * 根据_id是否存在逐条增加或者修改
   * @param entity
   */
  Future<int> upsert(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    var id = entity['id'];
    if (id != null) {
      return update(entity, ignore, parent);
    } else {
      return insert(entity, ignore, parent);
    }
  }
}
