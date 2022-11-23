import 'package:colla_chat/pages/chat/me/mail/mail_data_provider.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/localization.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_group_listview.dart';
import '../../../../widgets/data_bind/data_listtile.dart';

//邮件地址组件，带有回退回调函数
class MailAddressWidget extends StatefulWidget with TileDataMixin {
  const MailAddressWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailAddressWidgetState();

  @override
  String get routeName => 'mail_address';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.email);

  @override
  String get title => 'MailAddress';
}

class _MailAddressWidgetState extends State<MailAddressWidget> {
  late Widget mailAddressWidget;

  @override
  initState() {
    super.initState();
    mailAddressWidget = _build(context);
  }

  Icon _createIcon(String name) {
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

  _onTap(int index, String title, {String? subtitle,TileData? group}) {
    logger.w('index: $index, title: $title,onTap MailListWidget');
    var mailAddressProvider =
        Provider.of<MailDataProvider>(context, listen: false);
    mailAddressProvider.setCurrentMailboxName(title);
  }

  Widget _build(BuildContext context) {
    return Consumer<MailDataProvider>(
        builder: (context, mailAddressProvider, child) {
      Map<TileData, List<TileData>> mailAddressTileData = {};
      var mailAddresses = mailAddressProvider.mailAddresses;
      if (mailAddresses.isNotEmpty) {
        for (var mailAddress in mailAddresses) {
          TileData key = TileData(
              title: mailAddress.email, prefix: const Icon(Icons.email));
          List<enough_mail.Mailbox?>? mailboxes =
              mailAddressProvider.getMailboxes(mailAddress.email);
          if (mailboxes != null && mailboxes.isNotEmpty) {
            List<TileData> tiles = [];
            for (var mailbox in mailboxes) {
              if (mailbox != null) {
                Icon icon;
                var flags = mailbox.flags;
                if (flags.isNotEmpty) {
                  enough_mail.MailboxFlag flag = flags[0];
                  icon = _createIcon(flag.name);
                } else {
                  icon = _createIcon(mailbox.name);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: mailAddressWidget);

    return appBarView;
  }
}
