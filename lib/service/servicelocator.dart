import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/connect.dart';
import 'package:colla_chat/p2p/chain/action/ionsignal.dart';
import 'package:colla_chat/p2p/chain/action/p2pchat.dart';
import 'package:colla_chat/service/stock/account.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:dart_vlc/dart_vlc.dart';

import '../entity/p2p/security_context.dart';
import '../p2p/chain/action/chat.dart';
import '../p2p/chain/action/ping.dart';
import '../p2p/chain/action/signal.dart';
import '../p2p/chain/baseaction.dart';
import '../platform.dart';
import '../provider/app_data_provider.dart';
import 'chat/chat.dart';
import 'chat/contact.dart';
import 'chat/mailaddress.dart';
import 'dht/chainapp.dart';
import 'dht/myselfpeer.dart';
import 'dht/peerclient.dart';
import 'dht/peerendpoint.dart';
import 'dht/peerprofile.dart';
import 'dht/peersignal.dart';
import 'general_base.dart';
import 'p2p/security_context.dart';

class ServiceLocator {
  static Map<String, GeneralBaseService> services = {};
  static Map<MsgType, BaseAction> actions = {};
  static Map<int, SecurityContextService> securityContextServices = {};

  static GeneralBaseService? get(String serviceName) {
    return services[serviceName];
  }

  ///初始化并注册服务类，在应用启动后调用，返回值是是否自动登录成功
  static Future<bool> init() async {
    await platformParams.init();
    await appDataProvider.init();
    services['stockAccountService'] = stockAccountService;
    services['chainAppService'] = chainAppService;
    services['peerProfileService'] = peerProfileService;
    services['peerSignalService'] = peerSignalService;
    services['peerEndpointService'] = peerEndpointService;
    services['peerClientService'] = peerClientService;
    services['myselfPeerService'] = myselfPeerService;
    services['linkmanService'] = linkmanService;
    services['tagService'] = tagService;
    services['partyTagService'] = partyTagService;
    services['groupService'] = groupService;
    services['groupMemberService'] = groupMemberService;
    services['contactService'] = contactService;
    services['chatMessageService'] = chatMessageService;
    services['mergeMessageService'] = mergedMessageService;
    services['messageAttachmentService'] = messageAttachmentService;
    services['receiveService'] = receiveService;
    services['chatSummaryService'] = chatSummaryService;
    services['chat_mailaddress'] = mailAddressService;

    actions[MsgType.CONNECT] = connectAction;
    actions[MsgType.SIGNAL] = signalAction;
    actions[MsgType.CHAT] = chatAction;
    actions[MsgType.P2PCHAT] = p2pChatAction;
    actions[MsgType.PING] = pingAction;
    actions[MsgType.IONSIGNAL] = ionSignalAction;

    securityContextServices[CryptoOption.none.index] =
        noneSecurityContextService;
    securityContextServices[CryptoOption.compress.index] =
        compressSecurityContextService;
    securityContextServices[CryptoOption.cryptography.index] =
        cryptographySecurityContextService;
    securityContextServices[CryptoOption.signal.index] =
        signalSecurityContextService;

    await Sqlite3.getInstance();
    await AppLocalizations.init();
    bool loginStatus = await myselfPeerService.autoLogin();

    return loginStatus;
  }

  /// entity包含所有的字段，假设是字符串类型，fields是需要特别说明的字段，比如不是字符串类型
  /// 结果是fields中包含有全部的字段
  static List<String> buildFields(dynamic entity, List<String> fields) {
    Set<String> fs = {};
    for (var field in fields) {
      var f = field.substring(0, field.indexOf(' '));
      fs.add(f);
    }
    Map map = JsonUtil.toJson(entity);
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
