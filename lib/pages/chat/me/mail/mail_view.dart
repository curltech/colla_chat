import 'package:flutter/material.dart';

import '../../../../widgets/common/data_group_listview.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';

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
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var email = GroupDataListView(tileData: mailAddressTileData);
    return email;
  }
}
