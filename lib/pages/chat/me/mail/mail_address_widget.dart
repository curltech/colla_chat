import 'package:flutter/material.dart';

import '../../../../entity/chat/mailaddress.dart';
import '../../../../widgets/common/data_group_listview.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';
import 'mail_address_controller.dart';

//邮件地址组件，带有回退回调函数
class MailAddressWidget extends StatefulWidget
    with LeadingButtonMixin, RouteNameMixin {
  final Function? backCallBack;
  MailAddressController mailAddressController;

  MailAddressWidget(
      {Key? key, required this.mailAddressController, this.backCallBack})
      : super(key: key);

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
  initState() async {
    super.initState();
    widget.mailAddressController.addListener(() {
      setState(() {
        List<MailAddress> mailAddress =
            widget.mailAddressController.mailAddresses;
        for (var mailAddr in mailAddress) {
          TileData key =
              TileData(title: mailAddr.email!, icon: Icon(Icons.email));
          mailAddressTileData[key] = mailAddrTileData;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var email = Row(children: [
      GroupDataListView(tileData: mailAddressTileData),
    ]);
    return email;
  }
}
