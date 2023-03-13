import 'package:colla_chat/pages/chat/linkman/linkman/contact_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/nearby_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/p2p_linkman_add_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//增加联系人页面，列出了所有的增加联系人的路由
class LinkmanAddWidget extends StatelessWidget with TileDataMixin {
  final P2pLinkmanAddWidget p2pLinkmanAddWidget = P2pLinkmanAddWidget();
  final ContactLinkmanAddWidget contactLinkmanAddWidget =
      ContactLinkmanAddWidget();
  final NearbyLinkmanAddWidget nearbyLinkmanAddWidget =
      NearbyLinkmanAddWidget();

  late final List<TileData> linkmanAddTileData;

  LinkmanAddWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(p2pLinkmanAddWidget);
    indexWidgetProvider.define(contactLinkmanAddWidget);
    indexWidgetProvider.define(nearbyLinkmanAddWidget);
    List<TileDataMixin> mixins = [
      p2pLinkmanAddWidget,
      contactLinkmanAddWidget,
      nearbyLinkmanAddWidget,
    ];
    linkmanAddTileData = TileData.from(mixins);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman_add';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Add linkman';

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: linkmanAddTileData);
    var me = AppBarView(title: title, withLeading: true, child: child);
    return me;
  }
}
