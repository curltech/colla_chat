import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/service/stock/account.dart';
import 'package:colla_chat/tool/util.dart';

import '../entity/chat/chat.dart';
import '../entity/chat/contact.dart';
import '../entity/chat/mailaddress.dart';
import '../entity/dht/chainapp.dart';
import '../entity/dht/myselfpeer.dart';
import '../entity/dht/peerclient.dart';
import '../entity/dht/peerendpoint.dart';
import '../entity/dht/peerprofile.dart';
import '../entity/stock/account.dart';
import '../platform.dart';
import '../provider/app_data_provider.dart';
import 'base.dart';
import 'chat/chat.dart';
import 'chat/contact.dart';
import 'chat/mailaddress.dart';
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
    await PlatformParams.init();
    await AppDataProvider.init();
    var accountService = await StockAccountService.init(
        tableName: 'stk_account',
        fields: buildFields(StockAccount(), []),
        indexFields: ['accountId', 'accountName', 'status', 'updateDate']);
    services['accountService'] = accountService;

    var chainAppService = await ChainAppService.init(
        tableName: "blc_chainApp",
        fields: buildFields(ChainApp(), []),
        indexFields: []);
    services['chainAppService'] = chainAppService;

    var peerProfileService = await PeerProfileService.init(
        tableName: "blc_peerProfile",
        fields: buildFields(PeerProfile(), []),
        indexFields: ['peerId']);
    services['peerProfileService'] = peerProfileService;

    var peerEndpointService = await PeerEndpointService.init(
        tableName: "blc_peerEndpoint",
        fields: buildFields(PeerEndpoint(), []),
        indexFields: ['ownerPeerId', 'priority', 'address']);
    services['peerEndpointService'] = peerEndpointService;

    var peerClientService = await PeerClientService.init(
        tableName: "blc_peerClient",
        indexFields: ['peerId', 'name', 'mobile'],
        fields: buildFields(PeerClient(), []));
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
        fields: buildFields(MyselfPeer(), []));
    services['myselfPeerService'] = myselfPeerService;

    var linkmanService = await LinkmanService.init(
        tableName: 'chat_linkman',
        indexFields: [
          'givenName',
          'name',
          'ownerPeerId',
          'peerId',
          'mobile',
        ],
        fields: buildFields(Linkman('', '', ''), []));
    services['linkmanService'] = linkmanService;

    var tagService = await TagService.init(
        tableName: "chat_tag",
        indexFields: ['ownerPeerId', 'createDate', 'tag'],
        fields: buildFields(Tag(), []));
    services['tagService'] = tagService;

    var partyTagService = await PartyTagService.init(
        tableName: "chat_partyTag",
        indexFields: ['ownerPeerId', 'createDate', 'tag', 'partyPeerId'],
        fields: buildFields(PartyTag(), []));
    services['partyTagService'] = partyTagService;

    var partyRequestService = await PartyRequestService.init(
        tableName: "chat_partyRequest",
        indexFields: [
          'ownerPeerId',
          'createDate',
          'targetPeerId',
          'targetType',
          'status',
        ],
        fields: buildFields(PartyRequest('', '', ''), []));
    services['partyRequestService'] = partyRequestService;

    var groupService = await GroupService.init(
        tableName: "chat_group",
        indexFields: [
          'givenName',
          'name',
          'description',
          'ownerPeerId',
          'createDate',
          'peerId',
          'groupCategory',
          'groupType'
        ],
        fields: buildFields(Group('', '', ''), []));
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
        fields: buildFields(GroupMember(), []));
    services['groupMemberService'] = groupMemberService;

    var contactService = await ContactService.init(
        tableName: "chat_contact",
        indexFields: ['peerId', 'mobile', 'formattedName', 'name'],
        fields: buildFields(Contact('', '', ''), []));
    services['contactService'] = contactService;

    var chatMessageService = await ChatMessageService.init(
        tableName: "chat_message",
        indexFields: [
          'ownerPeerId',
          'transportType',
          'messageId',
          'messageType',
          'subMessageType',
          'direct',
          'targetPeerId',
          'targetType',
          'senderPeerId',
          'senderType',
          'createDate',
          'sendTime',
          'receiveTime',
          'actualReceiveTime',
          'title',
        ],
        fields: buildFields(ChatMessage(), []));
    services['chatMessageService'] = chatMessageService;

    var mergedMessageService = await MergedMessageService.init(
        tableName: "chat_mergedmessage",
        indexFields: [
          'ownerPeerId',
          'mergedMessageId',
          'messageId',
          'createDate'
        ],
        fields: buildFields(MergedMessage(), []));
    services['mergeMessageService'] = mergedMessageService;

    var messageAttachmentService = await MessageAttachmentService.init(
        tableName: "chat_messageattachment",
        indexFields: ['ownerPeerId', 'messageId', 'createDate', 'targetPeerId'],
        fields: buildFields(MessageAttachment(), []));
    services['messageAttachmentService'] = messageAttachmentService;

    var receiveService = await ReceiveService.init(
        tableName: "chat_receive",
        indexFields: [
          'ownerPeerId',
          'targetPeerId',
          'createDate',
          'targetType',
          'receiverPeerId',
          'messageType',
        ],
        fields: buildFields(Receive(), []));
    services['receiveService'] = receiveService;

    var chatService = await ChatService.init(
        tableName: "chat_chat",
        indexFields: ['ownerPeerId', 'peerId', 'sendReceiveTime'],
        fields: buildFields(Chat(), []));
    services['chatService'] = chatService;

    var mailAddressService = await MailAddressService.init(
        tableName: "chat_mailaddress",
        indexFields: ['ownerPeerId', 'email', 'name'],
        fields: buildFields(MailAddress(name: '', email: '@'), []));
    services['chat_mailaddress'] = mailAddressService;

    await Sqlite3.getInstance();

    // PlatformParams platformParams = await PlatformParams.instance;
    // if (platformParams.web) {
    //   await IndexedDb.getInstance();
    // } else {
    //   await Sqflite.getInstance();
    // }
  }

  /// entity包含所有的字段，假设是字符串类型，fields是需要特别说明的字段，比如不是字符串类型
  /// 结果是fields中包含有全部的字段
  static List<String> buildFields(dynamic entity, List<String> fields) {
    Set<String> fs = {};
    for (var field in fields) {
      var f = field.substring(0, field.indexOf(' '));
      fs.add(f);
    }
    Map map = JsonUtil.toMap(entity);
    for (var key in map.keys) {
      var value = map[key];
      if (key == 'id') {
        continue;
      }
      String? field;
      if (value != null) {
        if (value is int) {
          field = key + ' INT';
        } else if (value is double) {
          field = key + ' REAL';
        } else if (value is bool) {
          field = key + ' INT';
        } else if (value is DateTime) {
          field = key + ' TEXT';
        } else if (value is String) {
          field = key + ' TEXT';
        } else if (value is List) {
        } else {
          field = key + ' CLOB';
        }
      } else {
        field = key + ' TEXT';
      }
      if (field != null && !fs.contains(key)) {
        fields.add(field);
      }
    }

    return fields;
  }
}
