import 'package:flutter_contacts/flutter_contacts.dart';

class ContactUtil {
  ///请求权限
  static Future<PermissionStatus> requestPermission() async {
    return await FlutterContacts.permissions.request(PermissionType.readWrite);
  }

  ///获取所有电话联系人
  static Future<List<Contact>> getContacts() async {
    return await FlutterContacts.getAll(properties: ContactProperties.all);
  }

  ///通过id获取联系人
  static Future<Contact?> getContact(String id) async {
    return await FlutterContacts.get(
      id,
      properties: ContactProperties.all,
    );
  }

  ///打开外部联系人视图
  static Future<void>? showViewer(String id) async {
    return await FlutterContacts.native.showViewer(id);
  }

  ///打开外部联系人编辑视图
  static Future<String?> showEditor(String id) async {
    return await FlutterContacts.native.showEditor(id);
  }

  ///打开外部选择联系人视图
  static Future<String?> showPicker() async {
    final contact = await FlutterContacts.native.showPicker();

    return contact;
  }

  ///打开外部联系人增加视图
  static Future<String?> showCreator() async {
    final contact = await FlutterContacts.native.showCreator();

    return contact;
  }

  ///联系人修改监听器
  static void addListener(void Function(void) fn) {
    FlutterContacts.onDatabaseChange.listen(fn);
  }

  static Future<void> insert(Contact contact) async {
    await FlutterContacts.create(contact);
  }

  static Future<void> update(Contact contact) async {
    await FlutterContacts.update(contact);
  }

  static Future<void> delete(String id) async {
    await FlutterContacts.delete(id);
  }
}
