import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;

import '../../entity/chat/contact.dart';
import '../../entity/dht/peerclient.dart';
import '../../tool/util.dart';
import '../base.dart';
import '../dht/peerclient.dart';

abstract class PartyService extends BaseService {}

class LinkmanService extends PartyService {
  static final LinkmanService _instance = LinkmanService();
  static bool initStatus = false;

  static LinkmanService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<LinkmanService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }

  Future<List<Linkman>> search(String key) async {
    var where = 'peerId=? or mobile=? or name=? or pyName=? or mail=?';
    var whereArgs = [key, key, key, key, key];
    var linkmen_ = await find(where, whereArgs: whereArgs, orderBy: 'pyName');
    List<Linkman> linkmen = [];
    if (linkmen_.isNotEmpty) {
      for (var linkman_ in linkmen_) {
        var linkman = Linkman.fromJson(linkman_);
        linkmen.add(linkman);
      }
    }
    return linkmen;
  }

  Future<List<Linkman>> findAllLinkmen() async {
    var linkmen_ = await find(null, whereArgs: [], orderBy: 'pyName');
    List<Linkman> linkmen = [];
    if (linkmen_.isNotEmpty) {
      for (var linkman_ in linkmen_) {
        var linkman = Linkman.fromJson(linkman_);
        linkmen.add(linkman);
      }
    }
    return linkmen;
  }
}

class TagService extends BaseService {
  static final TagService _instance = TagService();
  static bool initStatus = false;

  static TagService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<TagService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class PartyTagService extends BaseService {
  static final PartyTagService _instance = PartyTagService();
  static bool initStatus = false;

  static PartyTagService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<PartyTagService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class PartyRequestService extends BaseService {
  static final PartyRequestService _instance = PartyRequestService();
  static bool initStatus = false;

  static PartyRequestService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<PartyRequestService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class GroupService extends PartyService {
  static final GroupService _instance = GroupService();
  static bool initStatus = false;

  static GroupService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<GroupService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class GroupMemberService extends BaseService {
  static final GroupMemberService _instance = GroupMemberService();
  static bool initStatus = false;

  static GroupMemberService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<GroupMemberService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class ContactService extends PartyService {
  static final ContactService _instance = ContactService();
  static bool initStatus = false;

  static ContactService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<ContactService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }

  Future<String> formatMobile(String mobile) async {
    return mobile;
  }

  /// 获取手机电话本的数据填充peerContacts数组，校验是否好友，是否存在peerId
  /// @param {*} peerContacts
  /// @param {*} linkmans
  fillPeerContact(List<dynamic> peerContacts, List<Linkman> linkmans) async {
    List<flutter_contacts.Contact> contacts = await ContactUtil.getContacts();
    // 把通讯录的数据规整化，包含手机号和名称，然后根据手机号建立索引
    var peerContactMap = Map();
    if (contacts.isNotEmpty) {
      for (var contact in contacts) {
        Contact peerContact =
            Contact('', '', contact.name.last + contact.name.first);
        if (contact.name != null) {
          peerContact.formattedName = contact.name.toString();
          //peerContact.pyFormattedName = pinyinUtil.getPinyin(peerContact.formattedName);
        }
        if (contact.phones != null && contact.phones.isNotEmpty) {
          for (var phoneNumber in contact.phones) {
            if (phoneNumber.isPrimary) {
              peerContact.mobile = phoneNumber.normalizedNumber;
              break;
            }
          }
          if (peerContact.mobile == null) {
            var mobile = contact.phones[0].normalizedNumber;
            peerContact.mobile = await formatMobile(mobile);
          }
        }
        peerContactMap[peerContact.mobile] = peerContact;
      }
    }
    // 遍历本地库的记录，根据手机号检查索引
    var pContacts = await findAll();
    if (pContacts.isNotEmpty) {
      for (var pContact in pContacts) {
        // 如果通讯录中存在，将本地匹配记录放入结果集
        var peerContact = peerContactMap[pContact['mobile']];
        if (peerContact) {
          peerContacts.add(pContact);
          peerContactMap.remove(pContact['mobile']);
        } else {
          // 如果通讯录不存在，则本地库删除
          this.delete(pContact);
        }
      }
    }
    // 通讯录中剩余的记录，新增的记录将被检查好友记录和服务器记录，然后插入本地库并加入结果集
    var leftPeerContacts = peerContactMap.values;
    if (leftPeerContacts != null) {
      for (var leftPeerContact in leftPeerContacts) {
        var pc = this.updateByLinkman(leftPeerContact, linkmans);
        if (pc == null) {
          pc = await this.refresh(leftPeerContact);
        }
        if (pc != null) {
          this.insert(leftPeerContact);
        }
        peerContacts.add(leftPeerContact);
      }
    }
  }

  Contact? updateByLinkman(Contact peerContact, List<Linkman> linkmans) {
    if (linkmans.isNotEmpty) {
      for (var linkman in linkmans) {
        if (linkman.mobile == peerContact.mobile) {
          peerContact.peerId = linkman.peerId;
          peerContact.name = linkman.name;
          peerContact.pyName = linkman.pyName;
          peerContact.givenName = linkman.givenName;
          peerContact.pyGivenName = linkman.pyGivenName;
          peerContact.locked = linkman.locked;
          peerContact.status = linkman.status;
          peerContact.publicKey = linkman.publicKey;
          peerContact.avatar = linkman.avatar;
          peerContact.isLinkman = true;

          return peerContact;
        }
      }
    }
    return null;
  }

  // 从服务器端获取是否有peerClient
  Future<Contact?> refresh(Contact peerContact) async {
    var mobile = peerContact.mobile;
    if (mobile != null) {
      var mobileNumber = await formatMobile(mobile);
      var peer = await peerClientService.findOneEffectiveByMobile(mobileNumber);
      if (peer != null) {
        var peerClient = PeerClient.fromJson(peer);
        peerContact.peerId = peerClient.peerId!;
        peerContact.name = peerClient.name;
        peerContact.status = peerClient.status;
        peerContact.publicKey = peerClient.publicKey;

        return peerContact;
      }
    }

    return null;
  }
}
