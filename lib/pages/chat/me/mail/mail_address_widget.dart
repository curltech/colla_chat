import 'package:colla_chat/pages/chat/me/mail/mail_address_provider.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../entity/chat/mailaddress.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../widgets/common/data_group_listview.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';

//邮件地址组件，带有回退回调函数
class MailAddressWidget extends StatefulWidget
    with LeadingButtonMixin, RouteNameMixin {
  final Function? leadingCallBack;

  const MailAddressWidget({Key? key, this.leadingCallBack}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailAddressWidgetState();

  @override
  String get routeName => 'mail_address';

  @override
  bool get withLeading => false;
}

class _MailAddressWidgetState extends State<MailAddressWidget> {
  Map<TileData, List<TileData>> mailAddressTileData = {};

  @override
  initState() {
    super.initState();
  }

  _connect(MailAddress mailAddress) {
    EmailClient? emailClient = EmailClientPool.instance.get(mailAddress.email);
    if (emailClient == null) {
      var password = mailAddress.password;
      if (password != null) {
        EmailClientPool.instance
            .create(mailAddress, password)
            .then((EmailClient? emailClient) {
          if (emailClient != null) {
            // emailClient
            //     .listMailboxesAsTree()
            //     .then((enough_mail.Tree<enough_mail.Mailbox?>? tree) {
            //   logger.i(tree!);
            // });
            emailClient.selectInbox().then((enough_mail.Mailbox? mailbox) {
              logger.i(mailbox!);
              emailClient
                  .fetchMessages(mailbox: mailbox)
                  .then((List<enough_mail.MimeMessage>? mimeMessages) {
                logger.i(mimeMessages!);
              }).catchError((err) {
                logger.e(err);
              });
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MailAddressProvider>(
        builder: (context, mailAddressProvider, child) {
      var mailAddresses = mailAddressProvider.mailAddresses;
      if (mailAddresses.isNotEmpty) {
        for (var mailAddress in mailAddresses) {
          _connect(mailAddress);
          TileData key =
              TileData(title: mailAddress.email, icon: const Icon(Icons.email));
          mailAddressTileData[key] = mailAddrTileData;
        }
      }
      var mailAddressWidget =
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: GroupDataListView(tileData: mailAddressTileData)),
      ]);
      return mailAddressWidget;
    });
  }
}
