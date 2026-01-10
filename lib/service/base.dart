import 'dart:async';

import 'package:colla_chat/tool/entity_util.dart';

import '../datastore/datastore.dart';
import '../entity/base.dart';

/// 范型化本地sqlite3的通用访问类，所有的表访问服务都是这个类的实例
abstract class BaseService {
  final String tableName;
  final List<String> fields;
  final List<String>? indexFields;
  late DataStore dataStore;

  BaseService(
      {required this.tableName, required this.fields, this.indexFields});

  Future<dynamic> get(int id, {dynamic Function(Map)? post}) {
    return findOne(where: 'id=?', whereArgs: [id], post: post);
  }

  Future<dynamic> findOne(
      {String? where,
      bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset,
      dynamic Function(Map)? post}) async {
    Map<dynamic, dynamic>? m = await dataStore.findOne(tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    if (m != null && post != null) {
      var o = post(m);
      return o;
    }

    return m;
  }

  Future<List<dynamic>> findAll({dynamic Function(Map)? post}) {
    return find(post: post);
  }

  /// 原生的查询
  Future<List<dynamic>> find(
      {String? where,
      bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset,
      dynamic Function(Map)? post}) async {
    var ms = await dataStore.find(tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);

    if (ms.isNotEmpty && post != null) {
      List<dynamic> os = [];
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
      return os;
    }

    return ms;
  }

  /// 与find的不同是返回值是带有result，from，limit，total字段的对象
  Future<Pagination> findPage(
      {String? where,
      bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int limit = defaultLimit,
      int offset = defaultOffset,
      dynamic Function(Map)? post}) async {
    var page = await dataStore.findPage(tableName,
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    var ms = page.data;
    if (ms.isNotEmpty && post != null) {
      List<dynamic> os = [];
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
      page.data = os;
    }

    return page;
  }

  /// 与find的区别是condi是普通对象，采用等于条件
  Future<List<dynamic>> seek(Map<String, Object> whereBean,
      {bool? distinct,
      List<String>? columns,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset,
      dynamic Function(Map)? post}) {
    var where = '1=1';
    List<Object> whereArgs = [];
    for (var key in whereBean.keys) {
      var value = whereBean[key];
      where = '$where and $key=?';
      whereArgs.add(value!);
    }
    return find(
        where: where,
        distinct: distinct,
        columns: columns,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        post: post);
  }

  Future<int> insert(dynamic entity, [dynamic ignore, dynamic parent]) async {
    EntityUtil.createTimestamp(entity);
    return await dataStore.insert(tableName, entity);
  }

  Future<int> delete(dynamic entity) async {
    return await dataStore.delete(tableName, entity: entity);
  }

  Future<int> update(dynamic entity, [dynamic ignore, dynamic parent]) async {
    EntityUtil.updateTimestamp(entity);
    return await dataStore.update(tableName, entity);
  }

  /// 批量保存，根据脏标志新增，修改或者删除
  FutureOr<Object?> save(List<Object> entities, [dynamic ignore, dynamic parent]) {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      operators.add({'table': tableName, 'entity': entity});
    }
    return dataStore.transaction(operators);
  }

  /// 根据_id是否存在逐条增加或者修改
  Future<int> upsert(dynamic entity, [dynamic ignore, dynamic parent]) async {
    var id = EntityUtil.getId(entity);
    if (id != null) {
      return await update(entity, ignore, parent);
    } else {
      return await insert(entity, ignore, parent);
    }
  }

  Future<List<dynamic>> findByStatus(String status,
      {Object Function(Map)? post}) async {
    var where = 'status = ?';
    var whereArgs = [status];
    var es = await find(where: where, whereArgs: whereArgs, post: post);

    return es;
  }

  Future<List<dynamic>> findEffective({Object Function(Map)? post}) async {
    return await findByStatus(EntityStatus.effective.name, post: post);
  }

  Future<dynamic> findOneEffective({Object Function(Map)? post}) async {
    var es = await findByStatus(EntityStatus.effective.name, post: post);
    if (es.isNotEmpty) {
      return es[0];
    }

    return null;
  }
}
