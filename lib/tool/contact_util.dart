import 'package:flutter_contacts/flutter_contacts.dart';

class ContactUtil {
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  static Future<List<Contact>> getContacts(
      {bool withProperties = true, bool withPhoto = true}) async {
    return await FlutterContacts.getContacts(
        withProperties: withProperties, withPhoto: withPhoto);
  }

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

  static Future<void>? openExternalView(String id) async {
    return await FlutterContacts.openExternalView(id);
  }

  static Future<Contact?> openExternalEdit(String id) async {
    return await FlutterContacts.openExternalEdit(id);
  }

  static Future<Contact?> openExternalPick() async {
    final contact = await FlutterContacts.openExternalPick();
    return contact;
  }

  static Future<Contact?> openExternalInsert() async {
    final contact = await FlutterContacts.openExternalInsert();
    return contact;
  }

  static addListener(void Function() fn) {
    // Listen to contact database changes
    FlutterContacts.addListener(fn);
  }

// Insert new contact
// final newContact = Contact()
//   ..name.first = 'John'
//   ..name.last = 'Smith'
//   ..phones = [Phone('555-123-4567')];
// await newContact.insert();
//
// // Update contact
// contact.name.first = 'Bob';
// await contact.update();
//
// // Delete contact
// await contact.delete();
}
