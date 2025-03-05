import 'package:colla_chat/tool/string_util.dart';

class Sql {
  late String clause;
  late List<Object?>? params;

  Sql(this.clause, [this.params]);

  @override
  String toString() {
    return '$clause\n$params';
  }
}

class SqlBuilder {
  SqlBuilder();

  /// 建表
  /// @param {*} tableName
  /// @param {*} fields
  List<String> create(String tableName, List<String> fields,
      {List<String>? uniqueFields, List<String>? indexFields}) {
    List<String> clauses = [];
    var query =
        'CREATE TABLE IF NOT EXISTS $tableName(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,';
    var i = 0;
    for (var field in fields) {
      if (i == 0) {
        query = query + field;
      } else {
        query = '$query, $field';
      }
      ++i;
    }
    query = '$query)';
    clauses.add(query);

    if (uniqueFields != null) {
      for (var uniqueField in uniqueFields) {
        query =
            'CREATE UNIQUE INDEX IF NOT EXISTS ${tableName}_${uniqueField}_uindex ON $tableName($uniqueField)';
        clauses.add(query);
      }
    }

    if (indexFields != null) {
      for (var indexField in indexFields) {
        query =
            'CREATE INDEX IF NOT EXISTS ${tableName}_$indexField ON $tableName($indexField)';
        clauses.add(query);
      }
    }

    return clauses;
  }

  /// 删除表
  /// @param {*} tableName
  String drop(String tableName) {
    var query = 'DROP TABLE IF EXISTS $tableName';

    return query;
  }

  /// 查询记录
  /// @param {*} tableName
  /// @param {*} fields
  /// @param {*} where
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
      query = '${query}DISTINCT';
    }
    var i = 0;
    if (columns != null && columns.isNotEmpty) {
      for (var field in columns) {
        if (i == 0) {
          query = query + field;
        } else {
          query = '$query, $field';
        }
        ++i;
      }
    } else {
      query = '$query*';
    }
    query = '$query FROM $table';
    if (StringUtil.isNotEmpty(where)) {
      query = '$query WHERE $where';
    }
    if (StringUtil.isNotEmpty(orderBy)) {
      query = '$query ORDER BY $orderBy';
    }
    if (StringUtil.isNotEmpty(groupBy)) {
      query = '$query GROUP BY $groupBy';
    }
    if (StringUtil.isNotEmpty(having)) {
      query = '$query HAVING $having';
    }
    if (limit != null && limit > 0) {
      query = '$query LIMIT $limit';
    }
    if (offset != null && offset > 0) {
      query = '$query OFFSET $offset';
    }

    return query;
  }

  /// 插入一条记录
  /// @param {*} tableName
  /// @param {*} entity
  Sql insert(String tableName, Map<String, dynamic> entity) {
    List<Object?>? params = [];
    var query = 'INSERT INTO $tableName (';
    var i = 0;
    var valueQuery = '';
    for (var key in entity.keys) {
      var param = entity[key];
      params.add(param);
      if (i == 0) {
        query = query + key;
        valueQuery = '$valueQuery?';
      } else {
        query = '$query, $key';
        valueQuery = '$valueQuery, ?';
      }
      ++i;
    }
    query = '$query) values ($valueQuery)';

    return Sql(query, params);
  }

  /// 删除记录
  /// @param {*} tableName
  /// @param {*} where
  Sql delete(String tableName, String where, [List<Object>? whereArgs]) {
    var query = 'DELETE FROM $tableName WHERE $where';

    return Sql(query, whereArgs);
  }

  /// 更新记录
  /// @param {*} tableName
  /// @param {*} entity
  /// @param {*} where
  Sql update(String tableName, Map<String, dynamic> entity, String where,
      [List<Object?>? whereArgs]) {
    var query = 'UPDATE $tableName SET ';
    var params = <Object?>[];
    var i = 0;
    for (var key in entity.keys) {
      var param = entity[key];
      params.add(param);
      if (i == 0) {
        query = '${query + key} = ?';
      } else {
        query = '${'$query, $key'} = ?';
      }
      ++i;
    }
    query = '$query WHERE $where';
    if (whereArgs != null) {
      params.addAll(whereArgs);
    }

    return Sql(query, params);
  }
}

var sqlBuilder = SqlBuilder();
