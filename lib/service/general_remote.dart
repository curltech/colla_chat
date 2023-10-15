import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:dio/dio.dart';

/// 远程存储服务的通用访问类，所有的表访问服务都是这个类的实例
abstract class GeneralRemoteService<T> {
  final String name;
  final int index = 0;
  String? httpConnectAddress;
  DioHttpClient? client;

  GeneralRemoteService({required this.name, this.httpConnectAddress}) {
    if (httpConnectAddress == null) {
      PeerEndpoint? defaultPeerEndpoint =
          peerEndpointController.defaultPeerEndpoint;
      if (defaultPeerEndpoint != null) {
        httpConnectAddress = defaultPeerEndpoint.httpConnectAddress;
      }
    }
    if (httpConnectAddress != null) {
      client = httpClientPool.get(httpConnectAddress!);
    }
  }

  dynamic send(String url, {dynamic data}) async {
    if (client != null) {
      Response<dynamic> response = await client!.send(url, data);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        logger.e('DioHttpClient send err:${response.statusCode}');
      }
    }
  }

  Future<T?> get(int id) async {
    return await findOne(condiBean: {'id': id});
  }

  Future<T?> findOne({
    String? where,
    bool? distinct,
    List<String>? columns,
    List<Object>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    dynamic condiBean,
  }) async {
    var url = '/${this.name}/Get';
    if (orderBy != null && orderBy.isNotEmpty) {
      url = '$url?orderby=$orderBy';
    }
    Map<String, dynamic> params = {};
    if (condiBean != null) {
      var json = JsonUtil.toJson(condiBean);
      params.addAll(json);
    }
    return send(url, data: params);
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
    dynamic condiBean,
  }) async {
    Map<String, dynamic> params = {};
    if (limit != null) {
      params['limit'] = limit;
    }
    if (orderBy != null) {
      params['orderby'] = orderBy;
    }
    if (offset != null) {
      params['from'] = offset;
    }
    if (condiBean != null) {
      params['condiBean'] = JsonUtil.toJson(condiBean);
    }
    var data = await send('/${this.name}/Find', data: params);

    return data;
  }

  /// 与find的不同是返回值是带有result，from，limit，total字段的对象
  Future<Pagination<T>> findPage(
      {String? where,
      bool? distinct,
      List<String>? columns,
      List<Object>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int limit = defaultLimit,
      int offset = defaultOffset,
      dynamic condiBean}) async {
    Map<String, dynamic> params = {'from': offset, 'limit': limit};
    if (orderBy != null) {
      params['orderby'] = orderBy;
    }
    if (condiBean != null) {
      params['condiBean'] = JsonUtil.toJson(condiBean);
    }
    var data = await send('/${this.name}/Find', data: params);
    Pagination<T> pagination = Pagination<T>(
        data: data.data,
        rowsNumber: data.count,
        offset: offset,
        rowsPerPage: limit);

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

  Future<int> insert(dynamic entity) async {
    EntityUtil.createTimestamp(entity);
    Map<String, dynamic> json = await JsonUtil.toJson(entity);
    dynamic responseData = await send('/${this.name}/Insert', data: [json]);
    Object? id = EntityUtil.getId(responseData);
    if (id == null) {
      EntityUtil.setId(entity, responseData);
    }
    return responseData;
  }

  /// 删除记录。根据entity的id字段作为条件删除，entity可以是Map
  Future<int> delete(
      {dynamic entity, String? where, List<Object>? whereArgs}) async {
    Map<String, dynamic> json = await JsonUtil.toJson(entity);
    dynamic responseData = await send('/${this.name}/Delete', data: [json]);

    return responseData;
  }

  /// 更新记录。根据entity的id字段作为条件，其他字段作为更新的值，entity可以是Map
  Future<int> update(
    dynamic entity, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    entity = EntityUtil.updateTimestamp(entity);
    List<Object> args = [];
    if (whereArgs != null) {
      args.addAll(whereArgs);
    }
    Map<String, dynamic> json = await JsonUtil.toJson(entity);
    dynamic responseData = await send('/${this.name}/Update', data: [json]);

    return responseData;
  }

  /// 批量保存，根据脏标志新增，修改或者删除
  save(List<T> entities, [dynamic ignore, dynamic parent]) async {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      Map<String, dynamic> json = await JsonUtil.toJson(entity);
      operators.add(json);
    }
    dynamic responseData = await send('/${this.name}/Save', data: operators);

    return responseData;
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
    var condiBean = {'status': status};
    var es = await find(condiBean: condiBean);

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
