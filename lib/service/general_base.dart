import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';

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

  String? _buildWhere(
    String? where,
    List<Object>? whereArgs,
  ) {
    if (whereArgs != null && myself.peerId != null) {
      if (StringUtil.isNotEmpty(where)) {
        where = '($where) and ownerPeerId=?';
      } else {
        where = 'ownerPeerId=?';
      }
      whereArgs.add(myself.peerId!);
    }
    return where;
  }

  Future<T?> get(int id) async {
    return await findOne(where: 'id=?', whereArgs: [id]);
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
    whereArgs = whereArgs ?? [];
    where = _buildWhere(where, whereArgs);
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

  Future<List<T>> findAll() async {
    return await find();
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
    whereArgs = whereArgs ?? [];
    where = _buildWhere(where, whereArgs);
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
    whereArgs = whereArgs ?? [];
    where = _buildWhere(where, whereArgs);
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
  }) async {
    var where = '1=1';
    List<Object> whereArgs = [];
    for (var key in whereBean.keys) {
      var value = whereBean[key];
      where = '$where and $key=?';
      whereArgs.add(value!);
    }
    return await find(
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
  Future<Map<String, dynamic>> encrypt(dynamic entity,
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
            List<int> raw = CryptoUtil.stringToUtf8(value!);
            securityContext.payload = raw;
            var result = await cryptographySecurityContextService
                .encrypt(securityContext);
            if (result) {
              json[encryptField] =
                  CryptoUtil.encodeBase64(securityContext.payload);
              json['payloadKey'] = securityContext.payloadKey;
              json['payloadHash'] = securityContext.payloadHash;
              json['needCompress'] = securityContext.needCompress;
              json['needEncrypt'] = securityContext.needEncrypt;
            }
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
            securityContext.payload = CryptoUtil.decodeBase64(value!);
            var result = await cryptographySecurityContextService
                .decrypt(securityContext);
            if (result) {
              var data = securityContext.payload;
              json[encryptField] = CryptoUtil.utf8ToString(data);
            }
          } catch (e) {
            logger.e('SecurityContextService decrypt err:$e');
          }
        }
      }
    }
    return json;
  }

  Future<int> insert(dynamic entity) async {
    EntityUtil.createTimestamp(entity);
    Map<String, dynamic> json = await encrypt(entity);
    int key = await dataStore.insert(tableName, json);
    Object? id = EntityUtil.getId(entity);
    if (id == null) {
      EntityUtil.setId(entity, key);
    }
    return key;
  }

  /// 删除记录。根据entity的id字段作为条件删除，entity可以是Map
  Future<int> delete(
      {dynamic entity, String? where, List<Object>? whereArgs}) async {
    whereArgs = whereArgs ?? [];
    where = _buildWhere(where, whereArgs);
    return await dataStore.delete(tableName,
        entity: entity, where: where, whereArgs: whereArgs);
  }

  /// 更新记录。根据entity的id字段作为条件，其他字段作为更新的值，entity可以是Map
  Future<int> update(
    dynamic entity, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    EntityUtil.updateTimestamp(entity);
    whereArgs = whereArgs ?? [];
    where = _buildWhere(where, whereArgs);
    Map<String, dynamic> json = await encrypt(entity);
    int result = await dataStore.update(tableName, json,
        where: where, whereArgs: whereArgs);
    return result;
  }

  /// 批量保存，根据脏标志新增，修改或者删除
  save(List<T> entities, [dynamic? ignore, dynamic? parent]) async {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      Map<String, dynamic> json = await encrypt(entity);
      operators.add({'table': tableName, 'entity': json});
    }
    return await dataStore.transaction(operators);
  }

  /// 根据_id是否存在逐条增加或者修改
  Future<int> upsert(
    dynamic entity, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    var id = EntityUtil.getId(entity);
    if (id != null) {
      return await update(entity, where: where, whereArgs: whereArgs);
    } else {
      return await insert(
        entity,
      );
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
