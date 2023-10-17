import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/min_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/stock/share.dart';

class RemoteMinLineService extends GeneralRemoteService<MinLine> {
  RemoteMinLineService({required super.name}) {
    post = (Map map) {
      return MinLine.fromJson(map);
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
    List<dynamic> data = await send('/minline/FindMinLines', data: params);

    return data;
  }
}

final RemoteMinLineService remoteMinLineService =
    RemoteMinLineService(name: 'minline');
