import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/plugin/security_storage.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/stock_line.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';

final List<Option> inEventOption = [
  Option('红杏出墙', 'RedApricots', hint: '下跌盘整一段时间后，均线走平，形成弯月底，中阳放量站上13日线'),
  Option('鸿雁南回', 'SwanSouth', hint: '上涨过程中，缩量回调'),
  Option('三箭齐发', 'ThreeArrow', hint: '盘整一段时间后，均线汇聚走平，大阳放量'),
];

final List<Option> outEventOption = [
  Option('一剑穿心', 'SwordHeart', hint: '阴线，长上影线，量能放大'),
  Option('惊鸿照影', 'GreenShadow', hint: '阴线，开盘价低于昨日收盘价'),
  Option('石破天惊', 'StoneSky', hint: '阴线，最高价低于昨日最低价'),
];

class RemoteShareService extends GeneralRemoteService<Share> {
  RemoteShareService({required super.name}) {
    post = (Map map) {
      return Share.fromRemoteJson(map);
    };
  }

  /// 查询自选股的详细信息
  Future<List<dynamic>> sendFindMine() async {
    List<dynamic> data = await stockLineService
        .send('/share/GetMine', data: {'ts_code': shareService.subscription});

    return data;
  }

  /// 根据关键字搜索股票
  Future<List<Share>> sendSearchShare(String keyword) async {
    List<dynamic> data = await stockLineService
        .send('/share/Search', data: {'keyword': keyword});
    List<Share> shares = [];
    for (dynamic map in data) {
      Share share = Share.fromRemoteJson(map);
      shares.add(share);
      shareService.store(share);
    }

    return shares;
  }
}

final RemoteShareService remoteShareService = RemoteShareService(name: 'share');

class ShareService extends GeneralBaseService<Share> {
  /// 存储在本地存储中
  String _subscription = '';
  Map<String, Share> shares = {};

  ShareService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Share.fromJson(map);
    };
  }

  String get subscription {
    return _subscription;
  }

  init() async {
    String? value =
        await localSharedPreferences.get('subscription', encrypt: true);
    _subscription = value ?? '';
  }

  Future<Share?> findShare(String tsCode) async {
    if (!shares.containsKey(tsCode)) {
      Share? share = await findOne(where: 'tscode=?', whereArgs: [tsCode]);
      if (share == null) {
        share = await remoteShareService
            .sendFindOne(condiBean: {'ts_code': tsCode});
        if (share != null) {
          await store(share);
        }
      }
      if (share != null) {
        shares[tsCode] = share;
      }
    }
    return shares[tsCode];
  }

  store(Share share) async {
    Share? old = await findOne(where: 'tscode=?', whereArgs: [share.tsCode!]);
    if (old == null) {
      share.id = null;
    } else {
      share.id = old.id;
    }
    await upsert(share);
  }

  Future<void> add(Share share) async {
    await store(share);
    String tsCode = share.tsCode!;
    if (!_subscription.contains(tsCode)) {
      _subscription += '$tsCode,';
      await localSharedPreferences.save('subscription', _subscription,
          encrypt: true);
    }
  }

  Future<void> remove(String tsCode) async {
    if (_subscription.contains(tsCode)) {
      _subscription.replaceAll('$tsCode,', '');
      await localSharedPreferences.save('subscription', _subscription,
          encrypt: true);
    }
  }
}

final ShareService shareService = ShareService(
    tableName: 'stk_share',
    fields: ServiceLocator.buildFields(Share(), []),
    indexFields: ['tsCode', 'symbol', 'name', 'area', 'industry', 'sector']);
