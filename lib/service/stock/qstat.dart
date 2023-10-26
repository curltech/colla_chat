import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/entity/stock/qstat.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemoteQStatService extends GeneralRemoteService<QStat> {
  RemoteQStatService({required super.name}) {
    post = (Map map) {
      return QStat.fromJson(map);
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
    List<dynamic> data = await send('/qstat/FindMinLines', data: params);

    return data;
  }
}

final RemoteQStatService remoteQStatService = RemoteQStatService(name: 'qstat');
