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

  /// 查询自选股的最新日线
  Future<List<DayLine>> sendFindLatest(String tsCode) async {
    var params = {'ts_code': tsCode};
    dynamic ms = await send('/dayline/FindLatest', data: params);
    List<DayLine> dayLines = [];
    for (var m in ms) {
      var o = post(m);
      dayLines.add(o);
      String tsCode = o.tsCode;
      Share? share = await shareService.findShare(tsCode);
      if (share != null) {
        o.name = share.name;
      }
    }

    return dayLines;
  }

  /// 查询自选股的日线
  Future<Map<String, dynamic>> sendFindPreceding(String tsCode,
      {int? from, int? limit, int? endDate, int? count}) async {
    var params = {
      'ts_code': tsCode,
      'from': from,
      'limit': limit,
      'end_date': endDate,
      'count': count,
    };
    dynamic responseData = await send('/dayline/FindPreceding', data: params);
    count = responseData['count'];
    List ms = responseData['data'];
    List<DayLine> dayLines = [];
    for (var m in ms) {
      var o = post(m);
      dayLines.add(o);
      String tsCode = o.tsCode;
      Share? share = await shareService.findShare(tsCode);
      if (share != null) {
        o.name = share.name;
      }
    }
    responseData['data'] = dayLines;

    return responseData;
  }

  Future<List<dynamic>> sendFindRange(String tsCode,
      {int? startDate, int? endDate, int? limit}) async {
    var params = {
      'ts_code': tsCode,
      'start_date': startDate,
      'end_date': endDate,
      'limit': limit,
    };
    dynamic ms = await send('/dayline/FindRange', data: params);
    List<DayLine> dayLines = [];
    for (var m in ms) {
      var o = post(m);
      dayLines.add(o);
      String tsCode = o.tsCode;
      Share? share = await shareService.findShare(tsCode);
      if (share != null) {
        o.name = share.name;
      }
    }
    return dayLines;
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
    dynamic ms = await send('/dayline/Search', data: params);
    List<DayLine> dayLines = [];
    for (var m in ms) {
      var o = post(m);
      dayLines.add(o);
      String tsCode = o.tsCode;
      Share? share = await shareService.findShare(tsCode);
      if (share != null) {
        o.name = share.name;
      }
    }
    return dayLines;
  }

  /// 查询股票的买卖点
  Future<List<DayLine>> sendFindByCondContent(
      {String? tsCode,
      String? condContent,
      int? tradeDate,
      String? condParas}) async {
    Map<String, dynamic> params = {
      'cond_content': condContent,
    };
    if (tsCode != null) {
      params['ts_code'] = tsCode;
    }
    if (tradeDate != null) {
      params['trade_date'] = tradeDate;
    }
    if (condParas != null) {
      params['cond_paras'] = condParas;
    }
    var responseData = await send('/dayline/FindByCondContent', data: params);
    List<DayLine> dayLines = [];
    if (responseData != null &&
        responseData is Map &&
        responseData.isNotEmpty) {
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
}

final RemoteDayLineService remoteDayLineService =
    RemoteDayLineService(name: 'dayline');
