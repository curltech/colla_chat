import 'package:colla_chat/pages/chat/me/mail/address/auto_discover_widget.dart';
import 'package:colla_chat/pages/chat/me/mail/address/manual_add_widget.dart';
import 'package:colla_chat/pages/chat/me/mail/mail_address_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';

///邮件地址子视图
class MailAddressWidget extends StatefulWidget {
  final AutoDiscoverWidget autoDiscoverWidget = const AutoDiscoverWidget();
  final ManualAddWidget manualAddWidget = const ManualAddWidget();

  MailAddressWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(autoDiscoverWidget);
    indexWidgetProvider.define(manualAddWidget);
  }

  @override
  State<StatefulWidget> createState() => _MailAddressWidgetState();
}

class _MailAddressWidgetState extends State<MailAddressWidget> {
  @override
  initState() {
    super.initState();
  }

  ///创建邮件地址的目录的图标
  Icon _createDirectoryIcon(String name) {
    Icon icon;
    switch (name) {
      case 'inbox':
        icon = const Icon(Icons.inbox);
        break;
      case 'drafts':
        icon = const Icon(Icons.drafts);
        break;
      case 'sent':
        icon = const Icon(Icons.send);
        break;
      case 'trash':
        icon = const Icon(Icons.delete);
        break;
      case 'junk':
        icon = const Icon(Icons.garage);
        break;
      case 'mark':
        icon = const Icon(Icons.flag);
        break;
      case 'backup':
        icon = const Icon(Icons.backup);
        break;
      case 'evidence':
        icon = const Icon(Icons.approval);
        break;
      case 'ads':
        icon = const Icon(Icons.ads_click);
        break;
      case 'virus':
        icon = const Icon(Icons.coronavirus);
        break;
      case 'subscript':
        icon = const Icon(Icons.subscript);
        break;
      default:
        icon = const Icon(Icons.folder);
        break;
    }
    return icon;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    logger.w('index: $index, title: $title,onTap MailListWidget');
    mailAddressController.setCurrentMailboxName(title);
  }

  Widget _buildMailAddressWidget(BuildContext context) {
    Map<TileData, List<TileData>> mailAddressTileData = {};
    var mailAddresses = mailAddressController.mailAddresses;
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        TileData key =
            TileData(title: mailAddress.email, prefix: const Icon(Icons.email));
        List<enough_mail.Mailbox?>? mailboxes =
            mailAddressController.getMailboxes(mailAddress.email);
        if (mailboxes != null && mailboxes.isNotEmpty) {
          List<TileData> tiles = [];
          for (var mailbox in mailboxes) {
            if (mailbox != null) {
              Icon icon;
              var flags = mailbox.flags;
              if (flags.isNotEmpty) {
                enough_mail.MailboxFlag flag = flags[0];
                icon = _createDirectoryIcon(flag.name);
              } else {
                icon = _createDirectoryIcon(mailbox.name);
              }
              TileData tile = TileData(
                  title: mailbox.name, prefix: icon, routeName: 'mails');
              tiles.add(tile);
            }
          }
          mailAddressTileData[key] = tiles;
        }
      }
    }
    var mailAddressWidget = GroupDataListView(
      tileData: mailAddressTileData,
      onTap: _onTap,
    );

    return mailAddressWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ButtonBar(children: [
        IconButton(
            onPressed: () {
              indexWidgetProvider.push('mail_address_auto_discover');
            },
            icon: const Icon(Icons.auto_mode),
            tooltip: 'Auto discover address'),
        IconButton(
            onPressed: () {
              indexWidgetProvider.push('mail_address_manual_add');
            },
            icon: const Icon(Icons.handyman),
            tooltip: 'Manual add address')
      ]),
      _buildMailAddressWidget(context)
    ]);
  }
}
