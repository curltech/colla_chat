import 'package:colla_chat/datastore/sql_builder.dart';

import '../constant/base.dart';

enum EntityState {
  None,
  New,
  Modified,
  Deleted,
}

class Pagination<T> {
  int total;
  List<T> data;
  int offset = defaultOffset;
  int limit = 0;
  int page = 0;

  static int getPage(int offset, int limit) {
    int mod = offset % limit;
    int page = offset ~/ limit;
    if (mod > 0) {
      page++;
    }

    return page;
  }

  static int getPageCount(int total, int limit) {
    int mod = total % limit;
    int pageCount = total ~/ limit;
    if (mod > 0) {
      pageCount++;
    }

    return pageCount;
  }

  Pagination(
      {required this.total,
      required this.data,
      this.offset = 0,
      this.limit = 10});

  int get pageCount {
    return getPageCount(total, limit);
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
    if (off > total) {
      return total;
    }
    return off;
  }

  Pagination.fromJson(Map json)
      : total = json['total'],
        data = json['data'],
        offset = json['offset'],
        limit = json['limit'];

  Map<String, dynamic> toJson() =>
      {'total': total, 'data': data, 'offset': offset, 'limit': limit};
}

abstract class DataStore {
  ///建表和索引
  dynamic create(String tableName, List<String> fields,
      [List<String>? indexFields]);

  dynamic run(Sql sql);

  execute(List<Sql> sqls);

  Future<Object?> get(String table, dynamic id);

  Future<List<Map>> find(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  Future<Pagination> findPage(String table,
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
  Future<Map?> findOne(String table,
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
  Future<int> insert(String table, dynamic entity);

  /// 删除记录
  /// @param {*} tableName
  /// @param {*} condition
  Future<int> delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs});

  /// 更新记录
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} condition
  Future<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  Future<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  /// 在一个事务里面执行多个操作（insert,update,devare)
  /// operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
  /// @param {*} operators
  Future<Object?> transaction(List<Map<String, dynamic>> operators);
}
