import 'package:colla_chat/entity/mail/mail_address.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/mail/address/auto_discover_widget.dart';
import 'package:colla_chat/pages/mail/address/manual_add_widget.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/mail/mail_address.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;

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
    super.initState();
    mailMimeMessageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    int i = 0;
    for (MailAddress emailAddress in mailMimeMessageController.data) {
      if (emailAddress.email == group!.title) {
        mailMimeMessageController.currentIndex = i;
        break;
      }
      i++;
    }
    mailMimeMessageController.setCurrentMailbox(title);
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
                int index = i;
                int? id = mailAddress.id;
                if (id != null) {
                  mailAddressService.delete(where: 'id=?', whereArgs: [id]);
                  mailMimeMessageController.delete(index: index);
                  emailClientPool.close(email: mailAddress.email);
                }
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLocalizations.t('Delete'),
            ),
            selected: mailMimeMessageController.currentIndex == i);
        List<TileData> tiles = [];
        List<String>? mailboxNames =
            mailMimeMessageController.getMailboxNames(mailAddress.email);

        if (mailboxNames != null && mailboxNames.isNotEmpty) {
          String? currentMailboxName =
              mailMimeMessageController.currentMailboxName;
          for (var mailboxName in mailboxNames) {
            Icon icon =
                Icon(mailMimeMessageController.findDirectoryIcon(mailboxName));
            enough_mail.Mailbox? mailbox = mailMimeMessageController.getMailbox(
                mailAddress.email, mailboxName);
            String titleTail = '';
            if (mailbox != null) {
              titleTail = '${mailbox.messagesUnseen}/${mailbox.messagesExists}';
            }
            TileData tile = TileData(
                title: mailboxName,
                prefix: icon,
                titleTail: titleTail,
                selected: mailMimeMessageController.currentIndex == i &&
                    currentMailboxName == mailboxName);
            tiles.add(tile);
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
