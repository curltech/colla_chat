import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/service/stock/account.dart';
import 'package:colla_chat/tool/util.dart';

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
import 'general_base.dart';

class ServiceLocator {
  static Map<String, GeneralBaseService> services = {};

  static GeneralBaseService? get(String serviceName) {
    return services[serviceName];
  }

  ///初始化并注册服务类，在应用启动后调用
  static Future<void> init() async {
    await PlatformParams.init();
    await AppDataProvider.init();
    services['stockAccountService'] = stockAccountService;
    services['chainAppService'] = chainAppService;
    services['peerProfileService'] = peerProfileService;
    services['peerEndpointService'] = peerEndpointService;
    services['peerClientService'] = peerClientService;
    services['myselfPeerService'] = myselfPeerService;
    services['linkmanService'] = linkmanService;
    services['tagService'] = tagService;
    services['partyTagService'] = partyTagService;
    services['partyRequestService'] = partyRequestService;
    services['groupService'] = groupService;
    services['groupMemberService'] = groupMemberService;
    services['contactService'] = contactService;
    services['chatMessageService'] = chatMessageService;
    services['mergeMessageService'] = mergedMessageService;
    services['messageAttachmentService'] = messageAttachmentService;
    services['receiveService'] = receiveService;
    services['chatSummaryService'] = chatSummaryService;
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
