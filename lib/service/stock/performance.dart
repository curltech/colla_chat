import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemotePerformanceService extends GeneralRemoteService<Performance> {
  RemotePerformanceService({required super.name}) {
    post = (Map map) {
      return Performance.fromJson(map);
    };
  }

  /// 查询自选股的最新日线
  Future<dynamic> sendFindLatest(String tsCode) async {
    var params = {'ts_code': tsCode};
    dynamic responseData = await send('/performance/FindLatest', data: params);
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
