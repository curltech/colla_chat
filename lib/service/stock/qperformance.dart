import 'package:colla_chat/entity/stock/qperformance.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemoteQPerformanceService extends GeneralRemoteService<QPerformance> {
  RemoteQPerformanceService({required super.name}) {
    post = (Map map) {
      return QPerformance.fromJson(map);
    };
  }

  /// 查询自选股的最新日线
  Future<dynamic> sendFindByQDate(
      {String? tsCode,
      String? startDate,
      String? orderBy,
      int? from,
      int? limit,
      int? count}) async {
    Map<String, dynamic> params = {};
    if (tsCode != null) {
      params['ts_code'] = tsCode;
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
    dynamic responseData =
        await send('/qperformance/FindByQDate', data: params);
    List<QPerformance> performances = [];
    for (var m in responseData['data']) {
      var o = post(m);
      performances.add(o);
    }
    responseData['data'] = performances;

    return responseData;
  }
}

final RemoteQPerformanceService remoteQPerformanceService =
    RemoteQPerformanceService(name: 'qperformance');
