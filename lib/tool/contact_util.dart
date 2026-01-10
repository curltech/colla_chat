import 'package:flutter_contacts/flutter_contacts.dart';

class ContactUtil {
  ///请求权限
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  ///获取所有电话联系人
  static Future<List<Contact>> getContacts(
      {bool withProperties = true, bool withPhoto = true}) async {
    return await FlutterContacts.getContacts(
        withProperties: withProperties, withPhoto: withPhoto);
  }

  ///通过id获取联系人
  static Future<Contact?> getContact(
    String id, {
    bool withProperties = true,
    bool withThumbnail = true,
    bool withPhoto = true,
    bool withGroups = false,
    bool withAccounts = false,
    bool deduplicateProperties = true,
  }) async {
    return await FlutterContacts.getContact(
      id,
      withProperties: withProperties,
      withThumbnail: withThumbnail,
      withPhoto: withPhoto,
      withGroups: withGroups,
      withAccounts: withAccounts,
      deduplicateProperties: deduplicateProperties,
    );
  }

  ///打开外部联系人视图
  static Future<void>? openExternalView(String id) async {
    return await FlutterContacts.openExternalView(id);
  }

  ///打开外部联系人编辑视图
  static Future<Contact?> openExternalEdit(String id) async {
    return await FlutterContacts.openExternalEdit(id);
  }

  ///打开外部选择联系人视图
  static Future<Contact?> openExternalPick() async {
    final contact = await FlutterContacts.openExternalPick();
    return contact;
  }

  ///打开外部联系人增加视图
  static Future<Contact?> openExternalInsert() async {
    final contact = await FlutterContacts.openExternalInsert();
    return contact;
  }

  ///联系人修改监听器
  static void addListener(void Function() fn) {
    // Listen to contact database changes
    FlutterContacts.addListener(fn);
  }

  static Future<void> insert(Contact contact) async {
    await contact.insert();
  }

  static Future<void> update(Contact contact) async {
    await contact.update();
  }

  static Future<void> delete(Contact contact) async {
    await contact.delete();
  }
}
