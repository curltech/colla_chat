import 'package:colla_chat/entity/stock/min_line.dart';
import 'package:colla_chat/entity/stock/qperformance.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemoteQPerformanceService extends GeneralRemoteService<QPerformance> {
  RemoteQPerformanceService({required super.name}) {
    post = (Map map) {
      return QPerformance.fromJson(map);
    };
  }

  /// 查询自选股的分钟线
  Future<List<dynamic>> sendFindMinLines(String tsCode,
      {int? tradeDate, int? tradeMinute}) async {
    var params = {
      'ts_code': tsCode,
      'trade_date': tradeDate,
      'trade_minute': tradeMinute
    };
    List<dynamic> data = await send('/performance/FindMinLines', data: params);

    return data;
  }
}

final RemoteQPerformanceService remoteQPerformanceService =
    RemoteQPerformanceService(name: 'qperformance');
