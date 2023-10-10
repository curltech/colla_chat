import 'package:colla_chat/entity/stock/share.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class ShareService extends GeneralBaseService<Share> {
  ShareService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Share.fromJson(map);
    };
  }
}

final ShareService shareService = ShareService(
    tableName: 'stk_share',
    fields: ServiceLocator.buildFields(Share(), []),
    indexFields: ['tsCode', 'symbol', 'name', 'area', 'industry', 'sector']);
