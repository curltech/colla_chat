import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/entity/stock/qstat.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemoteQStatService extends GeneralRemoteService<QStat> {
  RemoteQStatService({required super.name}) {
    post = (Map map) {
      return QStat.fromJson(map);
    };
  }

  /// 查询统计结果
  Future<dynamic> sendFindQStatBy(
      {String? tsCode,
      List<dynamic>? terms,
      List<dynamic>? source,
      String? sourceName,
      String? orderBy,
      int? from,
      int? limit,
      int? count}) async {
    Map<String, dynamic> params = {};
    if (tsCode != null) {
      params['ts_code'] = tsCode;
    }
    if (terms != null) {
      params['terms'] = terms;
    }
    if (source != null) {
      params['source'] = source;
    }
    if (sourceName != null) {
      params['sourceName'] = sourceName;
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
    dynamic responseData = await send('/qstat/FindQStatBy', data: params);
    List<QStat> stats = [];
    for (var m in responseData['data']) {
      var o = post(m);
      stats.add(o);
    }
    responseData['data'] = stats;

    return responseData;
  }
}

final RemoteQStatService remoteQStatService = RemoteQStatService(name: 'qstat');
