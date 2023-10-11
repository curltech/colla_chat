import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/share_group.dart';
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
    PeerEndpoint? defaultPeerEndpoint =
        peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      String? httpConnectAddress = defaultPeerEndpoint.httpConnectAddress;
      if (httpConnectAddress != null) {
        DioHttpClient? client = httpClientPool.get(httpConnectAddress);
        if (client != null) {
          // 数据为逗号分割的tscode
          var response = await client.send('/share/GetMine',
              {'ts_code': shareGroupService.groupSubscription});
        }
      }
    }
  }
}

final ShareService shareService = ShareService(
    tableName: 'stk_share',
    fields: ServiceLocator.buildFields(Share(), []),
    indexFields: ['tsCode', 'symbol', 'name', 'area', 'industry', 'sector']);
