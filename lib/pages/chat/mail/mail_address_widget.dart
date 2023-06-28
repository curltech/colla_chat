import 'package:colla_chat/entity/chat/mailaddress.dart';
import 'package:colla_chat/pages/chat/mail/address/auto_discover_widget.dart';
import 'package:colla_chat/pages/chat/mail/address/manual_add_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
    mailAddressController.addListener(_update);
    mailAddressController.refresh();
    super.initState();
  }

  _update() {
    setState(() {});
  }

  ///创建邮件地址的目录的图标
  IconData? _createDirectoryIcon(String name) {
    for (var mailBox in MailAddressController.mailBoxes) {
      if (mailBox.name == name) {
        return mailBox.iconData;
      }
    }
    return Icons.folder;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    int i = 0;
    for (MailAddress mailAddress in mailAddressController.data) {
      if (mailAddress.email == group!.title) {
        mailAddressController.currentIndex = i;
        break;
      }
      i++;
    }
    mailAddressController.currentMailboxName = title;
  }

  Widget _buildMailAddressWidget(BuildContext context) {
    Map<TileData, List<TileData>> mailAddressTileData = {};
    var mailAddresses = mailAddressController.data;
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        TileData key =
            TileData(title: mailAddress.email, subtitle: mailAddress.name);
        List<TileData> tiles = [];
        List<enough_mail.Mailbox?>? mailboxes =
            mailAddressController.getMailboxes(mailAddress.email);
        if (mailboxes != null && mailboxes.isNotEmpty) {
          for (var mailbox in mailboxes) {
            if (mailbox != null) {
              Icon icon;
              var flags = mailbox.flags;
              if (flags.isNotEmpty) {
                enough_mail.MailboxFlag flag = flags[0];
                icon = Icon(_createDirectoryIcon(flag.name));
              } else {
                icon = Icon(_createDirectoryIcon(mailbox.name));
              }
              TileData tile = TileData(title: mailbox.name, prefix: icon);
              tiles.add(tile);
            }
          }
        }
        mailAddressTileData[key] = tiles;
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
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
