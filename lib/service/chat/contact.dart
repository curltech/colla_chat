import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/service/chat/peer_party.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/contact_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;

class ContactService extends PeerPartyService<Contact> {
  ContactService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Contact.fromJson(map);
    };
  }

  Future<String> formatMobile(String mobile) async {
    return mobile;
  }

  /// 获取手机电话本的数据填充peerContacts数组，校验是否好友，是否存在peerId
  Future<List<Contact>> syncContact() async {
    List<flutter_contacts.Contact> mobileContacts =
        await ContactUtil.getContacts();
    // 把通讯录的数据规整化，包含手机号和名称，然后根据手机号建立索引
    var mobileContactMap = {};
    if (mobileContacts.isNotEmpty) {
      for (var mobileContact in mobileContacts) {
        Contact contact =
            Contact('', mobileContact.name.last + mobileContact.name.first);
        contact.formattedName = contact.name.toString();
        //contact.pyFormattedName = pinyinUtil.getPinyin(contact.formattedName);
        if (mobileContact.phones.isNotEmpty) {
          for (var phoneNumber in mobileContact.phones) {
            if (phoneNumber.isPrimary) {
              contact.mobile = phoneNumber.normalizedNumber;
              break;
            }
          }
          if (contact.mobile == null) {
            var mobile = mobileContact.phones[0].normalizedNumber;
            contact.mobile = await formatMobile(mobile);
          }
        }
        mobileContactMap[contact.mobile] = contact;
      }
    }
    // 遍历本地库的记录，根据手机号检查索引
    List<Contact> lastContacts = [];
    List<Contact> contacts = await findAll();
    if (contacts.isNotEmpty) {
      for (var contact in contacts) {
        // 如果通讯录中存在，将本地匹配记录放入结果集
        var mobile = contact.mobile;
        var mobileContact = mobileContactMap[mobile];
        if (mobileContact != null) {
          mobileContactMap.remove(mobile);
          lastContacts.add(contact);
        } else {
          // 如果通讯录不存在，则本地库删除
          delete(entity: contact);
        }
      }
    }
    // 通讯录中剩余的记录，新增的记录将被检查好友记录和服务器记录，然后插入本地库并加入结果集
    var leftContacts = mobileContactMap.values;
    for (var leftContact in leftContacts) {
      await insert(leftContact);
      lastContacts.add(leftContact);
    }

    return lastContacts;
  }

  Future<List<Contact>> search(String key) async {
    if (StringUtil.isEmpty(key)) {
      return await findAll();
    }
    var where = 'peerId=? or mobile=? or name=? or pyName=? or email=?';
    var whereArgs = [key, key, key, key, key];
    var contacts = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'pyName',
    );
    return contacts;
  }

  // 从服务器端获取是否有peerClient
  Future<Contact?> refresh(Contact peerContact) async {
    var mobile = peerContact.mobile;
    if (mobile != null) {
      var mobileNumber = await formatMobile(mobile);
      var peerClient =
          await peerClientService.findOneEffectiveByMobile(mobileNumber);
      if (peerClient != null) {
        peerContact.peerId = peerClient.peerId;
        peerContact.name = peerClient.name;
        peerContact.status = peerClient.status;
        peerContact.publicKey = peerClient.publicKey;

        return peerContact;
      }
    }

    return null;
  }
}

final contactService = ContactService(
    tableName: "chat_contact",
    indexFields: ['peerId', 'mobile', 'formattedName', 'name'],
    fields: ServiceLocator.buildFields(Contact('', ''), []));
