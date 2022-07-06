import '../constant/base.dart';
import '../datastore/datastore.dart';
import '../entity/base.dart';
import '../tool/util.dart';

/// 本地sqlite3的通用访问类，所有的表访问服务都是这个类的实例
abstract class GeneralBaseService<T> {
  final String tableName;
  final List<String> fields;
  final List<String> indexFields;
  late final DataStore dataStore;
  late final T Function(Map) post;

  GeneralBaseService(
      {required this.tableName,
      required this.fields,
      required this.indexFields});

  Future<T?> get(int id) {
    return findOne(where: 'id=?', whereArgs: [id]);
  }

  Future<T?> findOne(
      {String? where,
      bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
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
    if (m != null) {
      var o = post(m);
      return o;
    }

    return null;
  }

  Future<List<T>> findAll() {
    return find();
  }

  /// 原生的查询
  Future<List<T>> find({
    String? where,
    bool? distinct,
    List<String>? columns,
    List<Object>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
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

    List<T> os = [];
    if (ms.isNotEmpty) {
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
    }

    return os;
  }

  /// 与find的不同是返回值是带有result，from，limit，total字段的对象
  Future<Pagination<T>> findPage({
    String? where,
    bool? distinct,
    List<String>? columns,
    List<Object>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int limit = defaultLimit,
    int offset = defaultOffset,
  }) async {
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
    List<T> os = [];
    if (ms.isNotEmpty) {
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
    }
    Pagination<T> pagination = Pagination<T>(
        data: os,
        rowsNumber: page.rowsNumber,
        offset: page.offset,
        rowsPerPage: page.limit);

    return pagination;
  }

  /// 与find的区别是condi是普通对象，采用等于条件
  Future<List<T>> seek(
    Map<String, Object> whereBean, {
    bool? distinct,
    List<String>? columns,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
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
    );
  }

  Future<int> insert(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    EntityUtil.createTimestamp(entity);
    return dataStore.insert(tableName, entity);
  }

  Future<int> delete(dynamic entity) {
    return dataStore.delete(tableName, entity: entity);
  }

  Future<int> update(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    EntityUtil.updateTimestamp(entity);
    return dataStore.update(tableName, entity);
  }

  /// 批量保存，根据脏标志新增，修改或者删除
  save(List<Object> entities, [dynamic? ignore, dynamic? parent]) {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      operators.add({'table': tableName, 'entity': entity});
    }
    return dataStore.transaction(operators);
  }

  /// 根据_id是否存在逐条增加或者修改
  Future<int> upsert(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    var id = EntityUtil.getId(entity);
    if (id != null) {
      return update(entity, ignore, parent);
    } else {
      return insert(entity, ignore, parent);
    }
  }

  Future<List<T>> findByStatus(String status) async {
    var where = 'status = ?';
    var whereArgs = [status];
    var es = await find(where: where, whereArgs: whereArgs);

    return es;
  }

  Future<List<T>> findEffective() async {
    return await findByStatus(EntityStatus.Effective.name);
  }

  Future<Object?> findOneEffective() async {
    var es = await findByStatus(EntityStatus.Effective.name);
    if (es.isNotEmpty) {
      return es[0];
    }

    return null;
  }
}
