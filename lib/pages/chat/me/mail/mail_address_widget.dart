import 'package:colla_chat/pages/chat/me/mail/mail_address_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/common/data_group_listview.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';

//邮件地址组件，带有回退回调函数
class MailAddressWidget extends StatefulWidget
    with LeadingButtonMixin, RouteNameMixin {
  final Function? leadingCallBack;

  MailAddressWidget({Key? key, this.leadingCallBack}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Consumer<MailAddressProvider>(
        builder: (context, mailAddressProvider, child) {
      var mailAddresses = mailAddressProvider.mailAddresses;
      if (mailAddresses.isNotEmpty) {
        for (var mailAddress in mailAddresses) {
          TileData key =
              TileData(title: mailAddress.email, icon: Icon(Icons.email));
          mailAddressTileData[key] = mailAddrTileData;
        }
      }
      var mailAddressWidget = Row(children: [
        GroupDataListView(tileData: mailAddressTileData),
      ]);
      return mailAddressWidget;
    });
  }
}
