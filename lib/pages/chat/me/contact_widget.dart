import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/contact_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactWidget extends StatefulWidget with TileDataMixin {
  const ContactWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'contact';

  @override
  State<StatefulWidget> createState() => _ContactWidgetState();

  @override
  IconData get iconData => Icons.contact_phone;

  @override
  String get title => 'Contact';
}

class _ContactWidgetState extends State<ContactWidget> {
  List<TileData> _tileData = [];

  @override
  void initState() {
    super.initState();
  }

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
  }

  _refresh() async {
    _tileData = [];
    List<Contact>? contacts = await loadContacts();
    if (contacts != null && contacts.isNotEmpty) {
      for (Contact contact in contacts) {
        final phones = contact.phones.map((e) => e.number).join(', ');
        final emails = contact.emails.map((e) => e.address).join(', ');
        final name = contact.name.toString();
        TileData tile = TileData(title: name, subtitle: phones);
        _tileData.add(tile);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: [
        IconButton(
            onPressed: () async {
              await _refresh();
            },
            icon: const Icon(Icons.refresh))
      ],
      child: DataListView(tileData: _tileData),
    );
  }
}
