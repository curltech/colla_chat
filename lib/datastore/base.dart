import 'package:colla_chat/datastore/indexeddb.dart';
import '../../datastore/indexeddb.dart';
import '../../datastore/sqflite.dart';

import '../entity/stock/account.dart';
import '../platform.dart';
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
  String? createDate;
  String? updateDate;
  String? entityId;
  String? state;

  BaseEntity();

  BaseEntity.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createDate = json['createDate'],
        updateDate = json['updateDate'];

  Map<String, dynamic> toJson() =>
      {'id': id, 'createDate': createDate, 'updateDate': updateDate};
}

abstract class StatusEntity extends BaseEntity {
  String? status;
  String? statusReason;
  String? statusDate;

  StatusEntity();

  StatusEntity.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        statusReason = json['statusReason'],
        statusDate = json['statusDate'],
        super.fromJson(json);

  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({'id': id, 'createDate': createDate, 'updateDate': updateDate});
    return json;
  }
}

/**
 * 本地sqlite3的通用访问类，所有的表访问服务都是这个类的实例
 */
abstract class BaseService {
  late String tableName;
  late List<String> fields;
  List<String>? indexFields;
  late DataStore dataStore;

  /**
   * 通用的初始化服务类的方法
   */
  static Future<BaseService> init(BaseService instance,
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    instance.tableName = tableName;
    instance.fields = fields;
    instance.indexFields = indexFields;

    return instance;
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
      operators.add({'table': tableName, 'entity': entity});
    }
    return dataStore.transaction(operators);
  }

  /**
   * 根据_id是否存在逐条增加或者修改
   * @param entity
   */
  Future<int> upsert(dynamic entity, [dynamic? ignore, dynamic? parent]) {
    return dataStore.upsert(tableName, entity);
  }
}

class ServiceLocator {
  static Map<String, BaseService> services = Map();

  static get(String serviceName) {
    return services[serviceName];
  }

  ///初始化并注册服务类，在应用启动后调用
  static init() async {
    var accountService = await AccountService.init(
        tableName: 'stk_account',
        fields: ['accountId', 'accountName', 'status', 'updateDate'],
        indexFields: ['accountId']);
    services['accountService'] = accountService;

    PlatformParams platformParams = await PlatformParams.getInstance();
    if (platformParams.web) {
      await IndexedDb.getInstance();
    } else {
      await Sqflite.getInstance();
    }
  }
}
