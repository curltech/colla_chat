import 'package:colla_chat/pages/chat/login/myself_peer_view_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///自己的本地账号组件
class MyselfPeerView extends StatefulWidget with TileDataMixin {
  const MyselfPeerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyselfPeerViewState();

  @override
  String get routeName => 'myself_peer_view';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.account_circle;

  @override
  String get title => 'MyselfPeerView';
}

class _MyselfPeerViewState extends State<MyselfPeerView> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: const MyselfPeerViewWidget());

    return appBarView;
  }
}
