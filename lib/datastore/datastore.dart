import 'dart:async';

import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/tool/pagination_util.dart';

const int defaultLimit = 10;
const int defaultOffset = 0;

/// 分页器
class Pagination<T> {
  List<T> data;
  int count;
  int offset = defaultOffset;
  int limit = defaultLimit;

  Pagination(
      {required this.data,
      this.count = -1,
      this.offset = defaultOffset,
      this.limit = defaultLimit});

  int get pagesNumber {
    return PaginationUtil.getPageCount(count, limit);
  }

  int get page {
    return PaginationUtil.getCurrentPage(offset, limit);
  }

  set page(int page) {
    if (page > 0) {
      offset = (page - 1) * limit;
    }
  }

  ///上一页的offset
  int previous() {
    if (offset < limit) {
      return 0;
    }
    return offset - limit;
  }

  ///下一页的offset
  int next() {
    var off = offset + limit;
    if (off > count) {
      return count;
    }
    return off;
  }

  Pagination.fromJson(Map json)
      : count = json['total'],
        data = json['data'],
        offset = json['offset'],
        limit = json['limit'];

  Map<String, dynamic> toJson() =>
      {'total': count, 'data': data, 'offset': offset, 'limit': limit};
}

const String dbname =
    String.fromEnvironment('dbname', defaultValue: 'colla_chat.db');

abstract class DataStore {
  FutureOr<bool> open();

  ///建表和索引
  dynamic create(String tableName, List<String> fields,
      {List<String>? indexFields, bool drop = false});

  dynamic run(Sql sql);

  execute(List<Sql> sqls);

  FutureOr<List<Map<String, dynamic>>> select(String sql,
      [List<Object?> parameters = const []]);

  FutureOr<Object?> get(String table, dynamic id);

  FutureOr<List<Map<String, dynamic>>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  FutureOr<Pagination> findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int limit = defaultLimit,
      int offset = defaultOffset});

  /// 查询单条记录
  /// @param {*} tableName
  /// @param {*} fields
  /// @param {*} condition
  FutureOr<Map<String, dynamic>?> findOne(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  /// 插入一条记录,假设entity时一个有id属性的Object，或者Map
  /// @param {*} tableName
  /// @param {*} entity
  FutureOr<int> insert(String table, dynamic entity);

  /// 删除记录
  /// @param {*} tableName
  /// @param {*} condition
  FutureOr<int> delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs});

  /// 更新记录
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} condition
  FutureOr<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  FutureOr<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  /// 在一个事务里面执行多个操作（insert,update,devare)
  /// operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
  /// @param {*} operators
  FutureOr<Object?> transaction(List<Map<String, dynamic>> operators);
}
