import '../tool/util.dart';

enum EntityState {
  None,
  New,
  Modified,
  Deleted,
}

class Sql {
  late String clause;
  late List<Object?>? params;

  Sql(String clause, [List<Object?>? params]) {
    this.clause = clause;
    this.params = params;
  }
}

class SqlBuilder {
  SqlBuilder() {}

  /**
   * 建表
   * @param {*} tableName
   * @param {*} fields
   */
  String create(String tableName, List<String> fields) {
    var query = 'CREATE TABLE IF NOT EXISTS ' +
        tableName +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT,';

    var i = 0;
    for (var field in fields) {
      if (i == 0) {
        query = query + field;
      } else {
        query = query + ', ' + field;
      }
      ++i;
    }
    query = query + ')';

    return query;
  }

  /**
   * 删除表
   * @param {*} tableName
   */
  String drop(String tableName) {
    var query = 'DROP TABLE IF EXISTS ' + tableName;

    return query;
  }

  /**
   * 查询记录
   * @param {*} tableName
   * @param {*} fields
   * @param {*} condition
   */
  String select(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    var query = 'SELECT ';
    if (distinct != null && distinct) {
      query = query + 'DISTINCT';
    }
    var i = 0;
    if (columns != null && columns.length > 0) {
      for (var field in columns) {
        if (i == 0) {
          query = query + field;
        } else {
          query = query + ', ' + field;
        }
        ++i;
      }
    } else {
      query = query + '*';
    }
    query = query + ' FROM ' + table;
    if (where != null) {
      query = query + ' WHERE ' + where;
    }
    if (orderBy != null) {
      query = query + ' ORDER BY ' + orderBy;
    }
    if (groupBy != null) {
      query = query + ' GROUP BY ' + groupBy;
    }
    if (having != null) {
      query = query + ' HAVING ' + having;
    }
    if (limit! > 0) {
      query = query + ' LIMIT ' + limit.toString();
    }
    if (offset! > 0) {
      query = query + ' OFFSET ' + offset.toString();
    }

    return query;
  }

  /**
   * 插入一条记录
   * @param {*} tableName
   * @param {*} entity
   */
  Sql insert(String tableName, dynamic entity) {
    var params = [];
    var query = 'INSERT INTO ' + tableName + ' (';
    var i = 0;
    var valueQuery = '';
    for (var key in entity) {
      var param = entity[key];
      params.add(param);
      if (i == 0) {
        query = query + key;
        valueQuery = valueQuery + '?';
      } else {
        query = query + ', ' + key;
        valueQuery = valueQuery + ', ' + '?';
      }
      ++i;
    }
    query = query + ') values (' + valueQuery + ')';

    return Sql(query, params);
  }

  /**
   * 删除记录
   * @param {*} tableName
   * @param {*} condition
   */
  String delete(String tableName, String condition) {
    var query = 'DELETE FROM ' + tableName + ' WHERE ' + condition;

    return query;
  }

  /**
   * 更新记录
   * @param {*} tableName
   * @param {*} entity
   * @param {*} condition
   */
  Sql update(String tableName, dynamic entity, String condition) {
    var query = 'UPDATE ' + tableName + ' SET ';
    var params = <Object>[];
    var i = 0;
    for (var key in entity) {
      var param = entity[key];
      params.add(param);
      if (i == 0) {
        query = query + key + ' = ?';
      } else {
        query = query + ', ' + key + ' = ?';
      }
      ++i;
    }
    query = query + ' WHERE ' + condition;

    return Sql(query, params);
  }
}

var sqlBuilder = new SqlBuilder();

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

  Future<Map<String, Object>> findPage(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  /**
   * 查询单条记录
   * @param {*} tableName
   * @param {*} fields
   * @param {*} condition
   */
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

  /**
   * 插入一条记录,假设entity时一个有id属性的Object，或者Map
   * @param {*} tableName
   * @param {*} entity
   */
  Future<int> insert(String table, dynamic entity);

  /**
   * 删除记录
   * @param {*} tableName
   * @param {*} condition
   */
  Future<int> delete(String table,
      {dynamic entity, String? where, List<Object>? whereArgs});

  /**
   * 更新记录
   * @param {*} tableName
   * @param {*} entity
   * @param {*} condition
   */
  Future<int> update(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  Future<int> upsert(String table, dynamic entity,
      {String? where, List<Object>? whereArgs});

  /**
   * 在一个事务里面执行多个操作（insert,update,devare)
   * operators是一个operator对象的数组，operator有四个属性（type，tableName，entity，condition）
   * @param {*} operators
   */
  Future<Object?> transaction(List<Map<String, dynamic>> operators);
}
