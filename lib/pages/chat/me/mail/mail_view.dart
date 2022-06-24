import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';
import 'mail_address_provider.dart';
import 'mail_address_widget.dart';

//邮件总体视图，带有回退回调函数
class MailView extends StatefulWidget with LeadingButtonMixin, RouteNameMixin {
  final Function? leadingCallBack;

  MailView({Key? key, this.leadingCallBack}) : super(key: key) {}

  @override
  State<StatefulWidget> createState() => _MailViewState();

  @override
  String get routeName => 'mail';

  @override
  bool get withLeading => true;
}

class _MailViewState extends State<MailView>
    with SingleTickerProviderStateMixin {
  Map<TileData, List<TileData>> mailAddressTileData = {};

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var mailAddressWidget = const MailAddressWidget();
    const List<Widget> children = <Widget>[];
    children.add(mailAddressWidget);
    var tabBarView = TabBarView(
      controller: TabController(length: children.length, vsync: this),
      children: children,
    );
    var child = AppBarView(
        title: 'Mail', withLeading: widget.withLeading, child: tabBarView);
    var appBarView = ChangeNotifierProvider<MailAddressProvider>.value(
        value: mailAddressProvider, child: child);

    return appBarView;
  }
}
