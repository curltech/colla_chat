import '../datastore/datastore.dart';
import '../entity/base.dart';
import '../tool/util.dart';

/// 本地sqlite3的通用访问类，所有的表访问服务都是这个类的实例
abstract class BaseService {
  late String tableName;
  late List<String> fields;
  List<String>? indexFields;
  late DataStore dataStore;

  /// 通用的初始化服务类的方法
  static Future<BaseService> init(BaseService instance,
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    instance.tableName = tableName;
    instance.fields = fields;
    instance.indexFields = indexFields;

    return instance;
  }

  Future<Map?> get(int id) {
    return dataStore.findOne(this.tableName, where: 'id=?', whereArgs: [id]);
  }

  Future<Map?> findOne(String? where,
      {bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    return dataStore.findOne(tableName,
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

  /// 原生的查询
  Future<List<Map>> find(String? where,
      {bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    return dataStore.find(tableName,
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

  /// 与find的不同是返回值是带有result，from，limit，total字段的对象
  Future<Map<String, Object>> findPage(String? where,
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

  /// 与find的区别是condi是普通对象，采用等于条件
  Future<List<Map>> seek(Map<String, Object> whereBean,
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
    return dataStore.find(tableName,
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

  Future<List<Map>> findByStatus(String status) async {
    var where = 'status = ?';
    var whereArgs = [status];
    var es = await find(where, whereArgs: whereArgs);

    return es;
  }

  Future<List<Map>> findEffective() async {
    return await findByStatus(EntityStatus.Effective.toString());
  }

  Future<Map?> findOneEffective() async {
    var es = await findByStatus(EntityStatus.Effective.toString());
    if (es.isNotEmpty) {
      return es[0];
    }

    return null;
  }
}
