import 'package:colla_chat/entity/stock/stat_score.dart';
import 'package:colla_chat/service/general_remote.dart';

class RemoteStatScoreService extends GeneralRemoteService<StatScore> {
  RemoteStatScoreService({required super.name}) {
    post = (Map map) {
      return StatScore.fromJson(map);
    };
  }

  /// 查询统计结果
  Future<dynamic> sendSearch(
      {String? keyword,
      String? tsCode,
      List<dynamic>? terms,
      String? orderBy,
      int? from,
      int? limit,
      int? count}) async {
    Map<String, dynamic> params = {};
    if (keyword != null) {
      params['keyword'] = keyword;
    }
    if (tsCode != null) {
      params['ts_code'] = tsCode;
    }
    if (terms != null) {
      params['terms'] = terms;
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
    dynamic responseData = await send('/statscore/Search', data: params);
    List<StatScore> statScores = [];
    for (var m in responseData['data']) {
      var o = post(m);
      statScores.add(o);
    }
    responseData['data'] = statScores;

    return responseData;
  }
}

final RemoteStatScoreService remoteStatScoreService =
    RemoteStatScoreService(name: 'statscore');
