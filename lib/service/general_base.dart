import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/provider/app_data_provider.dart';

import '../constant/base.dart';
import '../datastore/datastore.dart';
import '../entity/base.dart';
import '../tool/util.dart';
import 'p2p/cryptography_security_context.dart';

/// 本地sqlite3的通用访问类，所有的表访问服务都是这个类的实例
abstract class GeneralBaseService<T> {
  final String tableName;
  final List<String> fields;
  final List<String> indexFields;
  final List<String> encryptFields;
  late final DataStore dataStore;
  late final T Function(Map) post;

  GeneralBaseService(
      {required this.tableName,
      required this.fields,
      required this.indexFields,
      this.encryptFields = const []});

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
      var json = await decrypt(o);
      o = post(json);
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
        var json = await decrypt(o);
        o = post(json);
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
        var json = await decrypt(o);
        o = post(json);
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

  ///payloadKey：null，直接ecc加密
  ///‘’，产生新的对称密钥并返回
  ///有值，用于加密,secretKey有值，用于加密
  Future<Map<String, dynamic>> encrypt(T entity,
      {bool needCompress = true,
      bool needEncrypt = true,
      bool needSign = false,
      String? payloadKey,
      List<int>? secretKey}) async {
    Map<String, dynamic> json = JsonUtil.toJson(entity) as Map<String, dynamic>;
    if (encryptFields.isNotEmpty) {
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = needCompress;
      securityContext.needEncrypt = needEncrypt;
      securityContext.needSign = needSign;
      securityContext.payloadKey = payloadKey;
      securityContext.secretKey = secretKey;
      for (var encryptField in encryptFields) {
        String? value = json[encryptField];
        if (StringUtil.isNotEmpty(value)) {
          try {
            securityContext = await cryptographySecurityContextService.encrypt(
                CryptoUtil.decodeBase64(value!), securityContext);
            json[encryptField] = securityContext.transportPayload;
            json['payloadKey'] = securityContext.payloadKey;
            json['payloadHash'] = securityContext.payloadHash;
          } catch (err) {
            logger.e('SecurityContextService encrypt err:$err');
          }
        }
      }
    }
    return json;
  }

  ///payloadKey：空，直接ecc解密
  ///有值，用于加密,secretKey有值，用于解密
  Future<Map<String, dynamic>> decrypt(T entity,
      {bool needCompress = true,
      bool needEncrypt = true,
      bool needSign = false,
      String? payloadKey,
      List<int>? secretKey}) async {
    Map<String, dynamic> json = JsonUtil.toJson(entity) as Map<String, dynamic>;
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = needCompress;
    securityContext.needEncrypt = needEncrypt;
    securityContext.needSign = needSign;
    securityContext.payloadKey = payloadKey;
    securityContext.secretKey = secretKey;
    if (encryptFields.isNotEmpty) {
      for (var encryptField in encryptFields) {
        String? value = json[encryptField];
        if (StringUtil.isNotEmpty(value)) {
          try {
            List<int> data =
                await cryptographySecurityContextService.decrypt(value!, securityContext);
            json[encryptField] = CryptoUtil.encodeBase64(data);
          } catch (err) {
            logger.e('SecurityContextService decrypt err:$err');
          }
        }
      }
    }
    return json;
  }

  Future<int> insert(dynamic entity, [dynamic? ignore, dynamic? parent]) async {
    EntityUtil.createTimestamp(entity);
    Map<String, dynamic> json = await encrypt(entity);
    int key = await dataStore.insert(tableName, json);
    Object? id = EntityUtil.getId(entity);
    if (id == null) {
      EntityUtil.setId(entity, key);
    }
    return key;
  }

  Future<int> delete(dynamic entity) {
    return dataStore.delete(tableName, entity: entity);
  }

  Future<int> update(dynamic entity, [dynamic? ignore, dynamic? parent]) async {
    EntityUtil.updateTimestamp(entity);
    Map<String, dynamic> json = await encrypt(entity);
    return dataStore.update(tableName, json);
  }

  /// 批量保存，根据脏标志新增，修改或者删除
  save(List<T> entities, [dynamic? ignore, dynamic? parent]) async {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      Map<String, dynamic> json = await encrypt(entity);
      operators.add({'table': tableName, 'entity': json});
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
    return await findByStatus(EntityStatus.effective.name);
  }

  Future<Object?> findOneEffective() async {
    var es = await findByStatus(EntityStatus.effective.name);
    if (es.isNotEmpty) {
      return es[0];
    }

    return null;
  }
}
