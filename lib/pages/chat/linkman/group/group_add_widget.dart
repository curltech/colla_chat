import 'package:colla_chat/pages/chat/linkman/group/face_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/nearby_group_add_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//增加群页面，列出了所有的增加群的路由
class GroupAddWidget extends StatelessWidget with TileDataMixin {
  final LinkmanGroupEditWidget linkmanGroupEditWidget =
      LinkmanGroupEditWidget();
  final NearbyGroupAddWidget nearbyGroupAddWidget = NearbyGroupAddWidget();
  final FaceGroupAddWidget faceGroupAddWidget = FaceGroupAddWidget();

  late final List<TileData> linkmanAddTileData;

  GroupAddWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(linkmanGroupEditWidget);
    indexWidgetProvider.define(nearbyGroupAddWidget);
    indexWidgetProvider.define(faceGroupAddWidget);
    List<TileDataMixin> mixins = [
      linkmanGroupEditWidget,
      nearbyGroupAddWidget,
      faceGroupAddWidget,
    ];
    linkmanAddTileData = TileData.from(mixins);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'group_add';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Add group';

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: linkmanAddTileData);
    var me = AppBarView(title: title, withLeading: true, child: child);
    return me;
  }
}
