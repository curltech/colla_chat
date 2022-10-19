import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/nearby_group_add_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//增加群页面，列出了所有的增加群的路由
class GroupAddWidget extends StatelessWidget with TileDataMixin {
  final LinkmanGroupAddWidget linkmanGroupAddWidget = LinkmanGroupAddWidget();
  final NearbyGroupAddWidget nearbyGroupAddWidget = NearbyGroupAddWidget();

  late final Widget child;

  GroupAddWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(linkmanGroupAddWidget);
    indexWidgetProvider.define(nearbyGroupAddWidget);
    List<TileDataMixin> mixins = [
      linkmanGroupAddWidget,
      nearbyGroupAddWidget,
    ];
    final List<TileData> linkmanAddTileData = TileData.from(mixins);
    child = Expanded(child: DataListView(tileData: linkmanAddTileData));
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'group_add';

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Group Add';

  @override
  Widget build(BuildContext context) {
    var me = AppBarView(
        title: Text(AppLocalizations.t('Group Add')),
        withLeading: true,
        child: Column(children: [child]));
    return me;
  }
}
