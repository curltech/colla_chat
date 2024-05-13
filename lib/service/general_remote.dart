import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:dio/dio.dart';

/// 远程存储服务的通用访问类，所有的表访问服务都是这个类的实例
abstract class GeneralRemoteService<T> {
  late final T Function(Map) post;
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

  Future<T?> sendGet(int id) async {
    return await sendFindOne(condiBean: {'id': id});
  }

  Future<T?> sendFindOne({
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
      var json = JsonUtil.toRemoteJson(condiBean);
      params.addAll(json);
    }
    var ms = await send(url, data: params);
    List<T> os = [];
    if (ms.isNotEmpty) {
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
    }

    return os.firstOrNull;
  }

  Future<List<T>> sendFindAll() async {
    return await sendFind();
  }

  /// 原生的查询
  Future<List<T>> sendFind({
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
      params['condiBean'] = JsonUtil.toRemoteJson(condiBean);
    }
    dynamic data = await send('/${this.name}/Find', data: params);
    List<T> os = [];
    var ms = data['data'];
    if (ms.isNotEmpty) {
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
    }

    return os;
  }

  /// 与find的不同是返回值是带有result，from，limit，total字段的对象
  Future<Pagination<T>> sendFindPage(
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
      params['condiBean'] = JsonUtil.toRemoteJson(condiBean);
    }
    var data = await send('/${this.name}/Find', data: params);
    var ms = data['data'];
    List<T> os = [];
    if (ms.isNotEmpty) {
      for (var m in ms) {
        var o = post(m);
        os.add(o);
      }
    }
    Pagination<T> pagination = Pagination<T>(
        data: os,
        count: data['count'],
        offset: offset,
        limit: limit);

    return pagination;
  }

  /// 与find的区别是condi是普通对象，采用等于条件
  Future<List<T>> sendSeek(
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
    return await sendFind(
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

  Future<T?> sendInsert(dynamic entity) async {
    Map<String, dynamic> json = await JsonUtil.toRemoteJson(entity);
    List<dynamic> ms = await send('/${this.name}/Insert', data: [json]);
    T? o;
    if (ms.isNotEmpty) {
      Object? id = EntityUtil.getId(entity);
      dynamic m = ms.first;
      if (id == null) {
        id = EntityUtil.getId(m);
        if (id != null) {
          EntityUtil.setId(entity, id);
        }
      }
      o = post(m);
    }

    return o;
  }

  /// 删除记录。根据entity的id字段作为条件删除，entity可以是Map
  Future<T?> sendDelete(
      {dynamic entity, String? where, List<Object>? whereArgs}) async {
    Map<String, dynamic> json = await JsonUtil.toRemoteJson(entity);
    List<dynamic> ms = await send('/${this.name}/Delete', data: [json]);
    T? o;
    if (ms.isNotEmpty) {
      o = post(ms.first);
    }
    return o;
  }

  /// 更新记录。根据entity的id字段作为条件，其他字段作为更新的值，entity可以是Map
  Future<T?> sendUpdate(
    dynamic entity, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    List<Object> args = [];
    if (whereArgs != null) {
      args.addAll(whereArgs);
    }
    Map<String, dynamic> json = await JsonUtil.toRemoteJson(entity);
    List<dynamic> ms = await send('/${this.name}/Update', data: [json]);
    T? o;
    if (ms.isNotEmpty) {
      o = post(ms.first);
    }
    return o;
  }

  /// 批量保存，根据脏标志新增，修改或者删除
  sendSave(List<T> entities) async {
    List<Map<String, dynamic>> operators = [];
    for (var entity in entities) {
      Map<String, dynamic> json = await JsonUtil.toRemoteJson(entity);
      operators.add(json);
    }
    dynamic responseData = await send('/${this.name}/Save', data: operators);

    return responseData;
  }

  /// 根据_id是否存在逐条增加或者修改
  Future<T?> sendUpsert(
    dynamic entity, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    var id = EntityUtil.getId(entity);
    if (id != null) {
      return await sendUpdate(entity, where: where, whereArgs: whereArgs);
    } else {
      return await sendInsert(
        entity,
      );
    }
  }
}
