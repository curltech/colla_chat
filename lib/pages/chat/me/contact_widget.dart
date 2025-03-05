import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/contact_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactWidget extends StatelessWidget with TileDataMixin {
  List<TileData> _tileData = [];

  ContactWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'contact';

  @override
  IconData get iconData => Icons.contact_phone;

  @override
  String get title => 'Contact';

  

  Future<List<Contact>?> loadContacts() async {
    try {
      await ContactUtil.requestPermission();
      final sw = Stopwatch()..start();
      var contacts = await ContactUtil.getContacts();
      sw.stop();

      return contacts;
    } catch (e) {
      logger.e('Failed to get contacts:\n$e');
    }
    return null;
  }

  _refresh() async {
    _tileData = [];
    List<Contact>? contacts = await loadContacts();
    if (contacts != null && contacts.isNotEmpty) {
      for (Contact contact in contacts) {
        final phones = contact.phones.map((e) => e.number).join(', ');
        final emails = contact.emails.map((e) => e.address).join(', ');
        final name = contact.name.first + contact.name.last;
        TileData tile = TileData(title: name, subtitle: phones);
        _tileData.add(tile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      rightWidgets: [
        IconButton(
            onPressed: () async {
              await _refresh();
            },
            icon: const Icon(Icons.refresh))
      ],
      child: DataListView(
          itemCount: _tileData.length,
          itemBuilder: (BuildContext context, int index) {
            return _tileData[index];
          }),
    );
  }
}
