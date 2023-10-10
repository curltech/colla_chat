import 'package:colla_chat/entity/stock/share.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/transport/httpclient.dart';

class ShareService extends GeneralBaseService<Share> {
  ShareService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Share.fromJson(map);
    };
  }

  findMine() async {
    DioHttpClient? client = httpClientPool.get('');
    // 数据为逗号分割的tscode
    var response = await client?.send('/share/GetMine', {'ts_code': ''});
  }
}

final ShareService shareService = ShareService(
    tableName: 'stk_share',
    fields: ServiceLocator.buildFields(Share(), []),
    indexFields: ['tsCode', 'symbol', 'name', 'area', 'industry', 'sector']);
