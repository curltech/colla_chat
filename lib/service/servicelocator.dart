import 'package:colla_chat/service/stock/account.dart';

import '../datastore/indexeddb.dart';
import '../datastore/sqflite.dart';
import '../platform.dart';
import 'base.dart';
import 'chat/contact.dart';
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
    services['peerEndpointService'] = peerEndpointService;

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
          'email',
          'status',
          'updateDate'
        ],
        fields: []);
    services['myselfPeerService'] = myselfPeerService;

    var linkmanService = await LinkmanService.init(
        tableName: 'chat_linkman',
        indexFields: [
          'givenName',
          'name',
          'ownerPeerId',
          'peerId',
          'mobile',
          'collectionType'
        ],
        fields: []);
    services['linkmanService'] = linkmanService;

    var linkmanTagService = await LinkmanTagService.init(
        tableName: "chat_linkmanTag",
        indexFields: ['ownerPeerId', 'createDate', 'name'],
        fields: []);
    services['linkmanService'] = linkmanService;

    var linkmanTagLinkmanService = await LinkmanTagLinkmanService.init(
        tableName: "chat_linkmanTagLinkman",
        indexFields: ['ownerPeerId', 'createDate', 'tagId', 'linkmanPeerId'],
        fields: []);
    services['linkmanTagLinkmanService'] = linkmanTagLinkmanService;

    var linkmanRequestService = await LinkmanRequestService.init(
        tableName: "chat_linkmanRequest",
        indexFields: [
          'ownerPeerId',
          'createDate',
          'receiverPeerId',
          'senderPeerId',
          'status'
        ],
        fields: []);
    services['linkmanRequestService'] = linkmanRequestService;

    var groupService =
        await GroupService.init(tableName: "chat_group", indexFields: [
      'givenName',
      'name',
      'description',
      'ownerPeerId',
      'createDate',
      'groupId',
      'groupCategory',
      'groupType'
    ], fields: []);
    services['groupService'] = groupService;

    var groupMemberService = await GroupMemberService.init(
        tableName: "chat_groupmember",
        indexFields: [
          'ownerPeerId',
          'createDate',
          'groupId',
          'memberPeerId',
          'memberType'
        ],
        fields: []);
    services['groupMemberService'] = groupMemberService;

    var contactService = await ContactService.init(
        tableName: "chat_contact",
        indexFields: ['peerId', 'mobile', 'formattedName', 'name'],
        fields: []);
    services['contactService'] = contactService;

    PlatformParams platformParams = await PlatformParams.instance;
    if (platformParams.web) {
      await IndexedDb.getInstance();
    } else {
      await Sqflite.getInstance();
    }
  }
}
