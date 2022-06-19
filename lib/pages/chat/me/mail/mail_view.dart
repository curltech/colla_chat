import 'package:flutter/material.dart';

import '../../../../entity/chat/mailaddress.dart';
import '../../../../provider/app_data.dart';
import '../../../../service/chat/mailaddress.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/widget_mixin.dart';

final List<TileData> mailAddrTileData = [
  TileData(
      icon: Icon(Icons.inbox,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Inbox'),
  TileData(
      icon: Icon(Icons.mark_as_unread,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Unread'),
  TileData(
      icon: Icon(Icons.drafts,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Draft'),
  TileData(
      icon: Icon(Icons.send,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Sent'),
  TileData(
      icon: Icon(Icons.flag,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Mark'),
  TileData(
      icon: Icon(Icons.delete,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Deleted'),
  TileData(
      icon: Icon(Icons.bug_report,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Junk'),
  TileData(
      icon: Icon(Icons.ads_click,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Ads'),
];

//邮件总体视图，带有回退回调函数
class MailView extends StatefulWidget with BackButtonMixin, RouteNameMixin {
  final Function? backCallBack;

  MailView({Key? key, this.backCallBack}) : super(key: key) {}

  @override
  State<StatefulWidget> createState() => _MailViewState();

  @override
  String get routeName => 'mail';

  @override
  bool get withBack => false;
}

class _MailViewState extends State<MailView> {
  Map<TileData, List<TileData>> mailAddressTileData = {};

  @override
  initState() async {
    super.initState();
    Map<TileData, List<TileData>> mailAddressTileData = {};
    List<MailAddress> mailAddress =
        await MailAddressService.instance.findAllMailAddress();
    for (var mailAddr in mailAddress) {
      TileData key = TileData(title: mailAddr.email!, icon: Icon(Icons.email));
      mailAddressTileData[key] = mailAddrTileData;
    }
  }

  @override
  Widget build(BuildContext context) {
    var email = Row(children: [
      DataListView(tileData: mailAddressTileData),
    ]);
    return email;
  }
}
