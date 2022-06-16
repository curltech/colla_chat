import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/contact.dart';
import 'contact_item.dart';
import 'indicator_page_view.dart';

enum ClickType { select, open }

class ContactView extends StatelessWidget {
  final ScrollController sC;
  final List<ContactItem> functionButtons;
  final List<Linkman> contacts;
  final ClickType? type;
  final Function(dynamic data)? callback;

  ContactView({
    required this.sC,
    this.functionButtons = const [],
    this.contacts = const [],
    this.type,
    this.callback,
  });

  @override
  Widget build(BuildContext context) {
    List<String> data = [];
    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: ListView.builder(
        controller: sC,
        itemBuilder: (BuildContext context, int index) {
          if (index < functionButtons.length) return functionButtons[index];

          int _contactIndex = index - functionButtons.length;
          bool _isGroupTitle = true;
          Linkman _contact = contacts[_contactIndex];
          if (_contactIndex >= 1 &&
              _contact.ownerPeerId == contacts[_contactIndex - 1].ownerPeerId) {
            _isGroupTitle = false;
          }
          bool _isBorder = _contactIndex < contacts.length - 1 &&
              _contact.ownerPeerId == contacts[_contactIndex + 1].ownerPeerId;
          if (_contact.name != contacts[contacts.length - 1].name) {
            return ContactItem(
              avatar: _contact.avatar!,
              title: _contact.name,
              identifier: _contact.peerId!,
              groupTitle: _contact.ownerPeerId,
              isLine: _isBorder,
              type: type!,
              cancel: (v) {
                data.remove(v);
                callback!(data);
              },
              add: (v) {
                data.add(v);
                callback!(data);
              },
            );
          } else {
            return Column(children: <Widget>[
              ContactItem(
                avatar: _contact.avatar!,
                title: _contact.name,
                identifier: _contact.peerId!,
                groupTitle: _contact.ownerPeerId,
                isLine: false,
                type: type!,
                cancel: (v) {
                  data.remove(v);
                  callback!(data);
                },
                add: (v) {
                  data.add(v);
                  callback!(data);
                },
              ),
              HorizontalLine(),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  '${contacts.length}位联系人',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              )
            ]);
          }
        },
        itemCount: contacts.length + functionButtons.length,
      ),
    );
  }
}
