import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/stock/share.dart';

class RemoteDayLineService extends GeneralRemoteService<DayLine> {
  RemoteDayLineService({required super.name}) {
    post = (Map map) {
      return DayLine.fromJson(map);
    };
  }

  /// 查询自选股的日线
  Future<dynamic> sendFindPreceding(String tsCode,
      {int? from, int? limit, int? endDate, int? count}) async {
    var params = {
      'ts_code': tsCode,
      'from': from,
      'limit': limit,
      'end_date': endDate,
      'count': count,
    };
    dynamic data = await send('/dayline/FindPreceding', data: params);

    return data;
  }

  Future<List<dynamic>> sendFindRange(String tsCode,
      {int? startDate, int? endDate, int? limit}) async {
    var params = {
      'ts_code': tsCode,
      'start_date': startDate,
      'end_date': endDate,
      'limit': limit,
    };
    List<dynamic> data = await send('/dayline/FindRange', data: params);

    return data;
  }

  Future<dynamic> sendSearch(String tsCode,
      {int? from,
      int? limit,
      int? startDate,
      int? endDate,
      String? orderBy,
      int? count}) async {
    var params = {
      'ts_code': tsCode,
      'from': from,
      'limit': limit,
      'start_date': startDate,
      'end_date': endDate,
      'orderby': orderBy,
      'count': count,
    };
    dynamic data = await send('/dayline/Search', data: params);

    return data;
  }

  /// 查询股票的买卖点
  Future<List<DayLine>> sendFindInout(String eventCode,
      {String? tsCode, int? tradeDate, int? startDate, int? endDate}) async {
    Map<String, dynamic> params = {
      'event_code': eventCode,
    };
    if (tsCode != null) {
      params['ts_code'] = tsCode;
    }
    if (tradeDate != null) {
      params['trade_date'] = tradeDate;
    }
    if (startDate != null) {
      params['start_date'] = startDate;
    }
    if (endDate != null) {
      params['end_date'] = endDate;
    }
    var responseData = await send('/dayline/FindInOutEvent', data: params);
    List<DayLine> dayLines = [];
    if (responseData != null) {
      List ms = responseData['data'];
      for (var m in ms) {
        var o = post(m);
        dayLines.add(o);
        String tsCode = o.tsCode;
        Share? share = await shareService.findShare(tsCode);
        if (share != null) {
          o.name = share.name;
        }
      }
    }

    return dayLines;
  }

  /// 查询股票的买卖点
  Future<List<DayLine>> sendFindAllInout(String eventCode,
      {String? tsCode, int? startDate, int? endDate}) async {
    Map<String, dynamic> params = {
      'event_code': eventCode,
    };
    if (tsCode != null) {
      params['ts_code'] = tsCode;
    }
    if (startDate != null) {
      params['start_date'] = startDate;
    }
    if (endDate != null) {
      params['end_date'] = endDate;
    }
    var responseData =
        await await send('/dayline/FindAllInOutEvent', data: params);
    List<DayLine> dayLines = [];
    if (responseData != null) {
      List ms = responseData['data'];
      for (var m in ms) {
        var o = post(m);
        dayLines.add(o);
      }
    }

    return dayLines;
  }
}

final RemoteDayLineService remoteDayLineService = RemoteDayLineService(name: 'dayline');
