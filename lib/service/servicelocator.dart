import 'dart:io';

import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/main.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/action/connect.dart';
import 'package:colla_chat/p2p/chain/action/ionsignal.dart';
import 'package:colla_chat/p2p/chain/action/p2pchat.dart';
import 'package:colla_chat/p2p/chain/action/ping.dart';
import 'package:colla_chat/p2p/chain/action/signal.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/chat/mailaddress.dart';
import 'package:colla_chat/service/dht/chainapp.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/service/dht/peersignal.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/stock/account.dart';
import 'package:colla_chat/tool/json_util.dart';

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
    HttpOverrides.global = PlatformHttpOverrides();

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
    var defaultPeerEndpoint = peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      logger.i(
          'Default PeerEndpoint websocket address:${defaultPeerEndpoint.wsConnectAddress}');
    }

    Map<String, dynamic>? autoLogin = await myselfPeerService.autoCredential();
    if (autoLogin != null) {
      appDataProvider.autoLogin = true;
    } else {
      appDataProvider.autoLogin = false;
    }
    bool loginStatus = await myselfPeerService.autoLogin();
    logger.i(
        'AutoLogin setting:${appDataProvider.autoLogin},AutoLogin status:$loginStatus');

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
