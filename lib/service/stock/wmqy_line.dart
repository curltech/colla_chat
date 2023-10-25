import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/entity/stock/wmqy_line.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/stock/share.dart';

class RemoteWmqyLineService extends GeneralRemoteService<WmqyLine> {
  RemoteWmqyLineService({required super.name}) {
    post = (Map map) {
      return WmqyLine.fromJson(map);
    };
  }

  /// 查询自选股的周，月，季度，半年，年线
  Future<dynamic> sendFindLinePreceding(String tsCode,
      {int lineType = 102, //  102,103,104,105,106
      int? from,
      int? limit,
      int? endDate,
      int? count}) async {
    var params = {
      'ts_code': tsCode,
      'line_type': lineType,
      'from': from,
      'limit': limit,
      'end_date': endDate,
      'count': count,
    };
    dynamic responseData = await send('/wmqyline/FindPreceding', data: params);
    count = responseData['count'];
    List ms = responseData['data'];
    List<WmqyLine> wmqyLines = [];
    for (var m in ms) {
      var o = post(m);
      wmqyLines.add(o);
      String tsCode = o.tsCode;
      Share? share = await shareService.findShare(tsCode);
      if (share != null) {
        o.name = share.name;
      }
    }
    responseData['data'] = wmqyLines;

    return responseData;
  }
}

final RemoteWmqyLineService remoteWmqyLineService =
    RemoteWmqyLineService(name: 'wmqyline');
