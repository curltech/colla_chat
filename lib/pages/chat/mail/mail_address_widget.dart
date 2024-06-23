import 'package:colla_chat/entity/mail/email_address.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/address/auto_discover_widget.dart';
import 'package:colla_chat/pages/chat/mail/address/manual_add_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/mail/email_address.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';

///邮件地址子视图
class MailAddressWidget extends StatefulWidget {
  final AutoDiscoverWidget autoDiscoverWidget = const AutoDiscoverWidget();
  final ManualAddWidget manualAddWidget = const ManualAddWidget();

  MailAddressWidget({super.key}) {
    indexWidgetProvider.define(autoDiscoverWidget);
    indexWidgetProvider.define(manualAddWidget);
  }

  @override
  State<StatefulWidget> createState() => _MailAddressWidgetState();
}

class _MailAddressWidgetState extends State<MailAddressWidget> {
  @override
  initState() {
    mailMimeMessageController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    int i = 0;
    for (EmailAddress emailAddress in mailMimeMessageController.data) {
      if (emailAddress.email == group!.title) {
        mailMimeMessageController.currentIndex = i;
        break;
      }
      i++;
    }
    mailMimeMessageController.currentMailboxName = title;
  }

  Widget _buildMailAddressWidget(BuildContext context) {
    Map<TileData, List<TileData>> mailAddressTileData = {};
    var mailAddresses = mailMimeMessageController.data;
    if (mailAddresses.isNotEmpty) {
      int i = 0;
      for (var mailAddress in mailAddresses) {
        TileData groupTile = TileData(
            title: mailAddress.email,
            subtitle: mailAddress.name,
            prefix: IconButton(
              onPressed: () {
                int? id = mailAddress.id;
                if (id != null) {
                  emailAddressService.delete(where: 'id=?', whereArgs: [id]);
                  mailMimeMessageController.delete(index: i);
                }
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLocalizations.t('Delete'),
            ),
            selected: mailMimeMessageController.currentIndex == i);
        List<TileData> tiles = [];
        List<enough_mail.Mailbox?>? mailboxes =
            mailMimeMessageController.getMailboxes(mailAddress.email);
        if (mailboxes != null && mailboxes.isNotEmpty) {
          String? currentMailboxName =
              mailMimeMessageController.currentMailboxName;
          for (var mailbox in mailboxes) {
            if (mailbox != null) {
              Icon icon = Icon(
                  mailMimeMessageController.findDirectoryIcon(mailbox.name));
              TileData tile = TileData(
                  title: mailbox.name,
                  prefix: icon,
                  selected: mailMimeMessageController.currentIndex == i &&
                      currentMailboxName == mailbox.name);
              tiles.add(tile);
            }
          }
        }
        mailAddressTileData[groupTile] = tiles;
        i++;
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
    return _buildMailAddressWidget(context);
  }

  @override
  void dispose() {
    mailMimeMessageController.removeListener(_update);
    super.dispose();
  }
}
