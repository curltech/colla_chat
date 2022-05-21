import 'package:colla_chat/service/stock/account.dart';

import '../datastore/indexeddb.dart';
import '../datastore/sqflite.dart';
import '../platform.dart';
import 'base.dart';
import 'dht/chainapp.dart';
import 'dht/myselfpeer.dart';
import 'dht/peerclient.dart';
import 'dht/peerendpoint.dart';
import 'dht/peerprofile.dart';

class ServiceLocator {
  static Map<String, BaseService> services = Map();

  static get(String serviceName) {
    return services[serviceName];
  }

  ///初始化并注册服务类，在应用启动后调用
  static Future<void> init() async {
    var accountService = await StockAccountService.init(
        tableName: 'stk_account',
        fields: ['accountId', 'accountName', 'status', 'updateDate'],
        indexFields: ['accountId']);
    services['accountService'] = accountService;

    var chainAppService = await ChainAppService.init(
        tableName: "blc_chainApp", fields: [], indexFields: []);
    services['chainAppService'] = chainAppService;

    var peerProfileService = await PeerProfileService.init(
        tableName: "blc_peerProfile", fields: [], indexFields: ['peerId']);
    services['peerProfileService'] = peerProfileService;

    var peerEndpointService = await PeerEndpointService.init(
        tableName: "blc_peerEndpoint",
        fields: [],
        indexFields: ['ownerPeerId', 'priority', 'address']);
    services['peerProfileService'] = peerEndpointService;

    var peerClientService = await PeerClientService.init(
        tableName: "blc_peerClient",
        indexFields: ['peerId', 'name', 'mobile'],
        fields: []);
    services['peerClientService'] = peerClientService;

    var myselfPeerService = await MyselfPeerService.init(
        tableName: "blc_myselfPeer",
        indexFields: [
          'endDate',
          'peerId',
          'name',
          'mobile',
          'status',
          'updateDate'
        ],
        fields: []);
    services['myselfPeerService'] = myselfPeerService;

    PlatformParams platformParams = await PlatformParams.instance;
    if (platformParams.web) {
      await IndexedDb.getInstance();
    } else {
      await Sqflite.getInstance();
    }
  }
}
