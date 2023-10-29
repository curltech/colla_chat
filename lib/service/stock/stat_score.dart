import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/entity/stock/qstat.dart';
import 'package:colla_chat/entity/stock/stat_score.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemoteStatScoreService extends GeneralRemoteService<StatScore> {
  RemoteStatScoreService({required super.name}) {
    post = (Map map) {
      return StatScore.fromJson(map);
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
    List<dynamic> data = await send('/statscore/FindMinLines', data: params);

    return data;
  }
}

final RemoteStatScoreService remoteStatScoreService =
    RemoteStatScoreService(name: 'statscore');
