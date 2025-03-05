import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/stock_line.dart';

class RemoteShareService extends GeneralRemoteService<Share> {
  RemoteShareService({required super.name}) {
    post = (Map map) {
      return Share.fromRemoteJson(map);
    };
  }

  /// 查询自选股的详细信息
  Future<List<dynamic>> sendFindMine() async {
    List<dynamic> data = await stockLineService.send('/share/GetMine',
        data: {'ts_code': myShareController.subscription});

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

  Map<String, Share> shares = {};

  ShareService(
      {required super.tableName,
      required super.fields,
      super.uniqueFields = const [
        'tsCode',
      ],
      super.indexFields = const [
        'symbol',
        'name',
        'area',
        'industry',
        'sector'
      ],
      super.encryptFields}) {
    post = (Map map) {
      return Share.fromJson(map);
    };
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
}

final ShareService shareService = ShareService(
  tableName: 'stk_share',
  fields: ServiceLocator.buildFields(Share(), []),
);
