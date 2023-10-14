import 'package:colla_chat/entity/stock/share.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/stock_line.dart';

class ShareService extends GeneralBaseService<Share> {
  String? _subscription;

  ShareService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Share.fromJson(map);
    };
  }

  Future<String?> findSubscription() async {
    if (_subscription == null) {
      List<Share> shares = await shareService.findAll();
      _subscription = '';
      for (Share share in shares) {
        _subscription = '$_subscription${share.tsCode},';
      }
    }

    return _subscription;
  }

  /// 查询自选股的详细信息
  Future<List<dynamic>> findMine() async {
    // 数据为逗号分割的tscode
    String? subscription = await findSubscription();
    List<dynamic> data = [];
    if (subscription != null) {
      data = await stockLineService
          .send('/share/GetMine', {'ts_code': subscription});
    }

    return data;
  }

  /// 根据关键字搜索股票
  Future<List<Share>> searchShare(String keyword) async {
    List<dynamic> data =
        await stockLineService.send('/share/Search', {'keyword': keyword});
    List<Share> shares = [];
    for (dynamic map in data) {
      Share share = Share.fromRemoteJson(map);
      shares.add(share);
    }

    return shares;
  }

  Future<void> add(Share share) async {
    await insert(share);
    _subscription = null;
  }

  Future<void> remove(String tsCode) async {
    delete(where: 'tscode=?', whereArgs: [tsCode]);
    _subscription = null;
  }

  /// 查询自选股的日线
  Future<dynamic> findPreceding(String tsCode,
      {int? from, int? limit, int? endDate, int? count}) async {
    var params = {
      'ts_code': tsCode,
      'from': from,
      'limit': limit,
      'end_date': endDate,
      'count': count,
    };
    dynamic data =
        await stockLineService.send('/dayline/FindPreceding', params);

    return data;
  }

  Future<List<dynamic>> findRange(String tsCode,
      {int? startDate, int? endDate, int? limit}) async {
    var params = {
      'ts_code': tsCode,
      'start_date': startDate,
      'end_date': endDate,
      'limit': limit,
    };
    List<dynamic> data =
        await stockLineService.send('/dayline/FindRange', params);

    return data;
  }

  Future<dynamic> search(String tsCode,
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
    dynamic data = await stockLineService.send('/dayline/Search', params);

    return data;
  }

  /// 查询自选股的周，月，季度，半年，年线
  Future<dynamic> findLinePreceding(String tsCode,
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
    dynamic data =
        await stockLineService.send('/wmqyline/FindPreceding', params);

    return data;
  }

  /// 查询自选股的分钟线
  Future<List<dynamic>> findMinLines(String tsCode,
      {int? tradeDate, int? tradeMinute}) async {
    var params = {
      'ts_code': tsCode,
      'trade_date': tradeDate,
      'trade_minute': tradeMinute
    };
    List<dynamic> data =
        await stockLineService.send('/minline/FindMinLines', params);

    return data;
  }
}

final ShareService shareService = ShareService(
    tableName: 'stk_share',
    fields: ServiceLocator.buildFields(Share(), []),
    indexFields: ['tsCode', 'symbol', 'name', 'area', 'industry', 'sector']);
