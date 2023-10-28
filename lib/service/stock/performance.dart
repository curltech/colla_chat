import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemotePerformanceService extends GeneralRemoteService<Performance> {
  RemotePerformanceService({required super.name}) {
    post = (Map map) {
      return Performance.fromJson(map);
    };
  }

  /// 查询自选股的最新日线
  Future<dynamic> sendFindLatest(
      {String? securityCode,
      String? startDate,
      String? orderBy,
      int? from,
      int? limit,
      int? count}) async {
    Map<String, dynamic> params = {};
    if (securityCode != null) {
      params['security_code'] = securityCode;
    }
    if (startDate != null) {
      params['start_date'] = startDate;
    }
    if (orderBy != null) {
      params['orderby'] = orderBy;
    }
    if (from != null) {
      params['from'] = from;
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (count != null) {
      params['count'] = count;
    }
    dynamic responseData = await send('/performance/FindLatest', data: params);
    List<Performance> performances = [];
    for (var m in responseData['data']) {
      var o = post(m);
      performances.add(o);
    }
    responseData['data'] = performances;

    return responseData;
  }

  /// 查询自选股的最新日线
  Future<dynamic> sendFindByQDate(
      {String? securityCode,
      String? startDate,
      String? orderBy,
      int? from,
      int? limit,
      int? count}) async {
    Map<String, dynamic> params = {};
    if (securityCode != null) {
      params['security_code'] = securityCode;
    }
    if (startDate != null) {
      params['start_date'] = startDate;
    }
    if (orderBy != null) {
      params['orderby'] = orderBy;
    }
    if (from != null) {
      params['from'] = from;
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (count != null) {
      params['count'] = count;
    }
    dynamic responseData = await send('/performance/FindByQDate', data: params);
    List<Performance> performances = [];
    for (var m in responseData['data']) {
      var o = post(m);
      performances.add(o);
    }
    responseData['data'] = performances;

    return responseData;
  }
}

final RemotePerformanceService remotePerformanceService =
    RemotePerformanceService(name: 'performance');
