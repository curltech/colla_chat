import 'package:colla_chat/pages/pip/background_pip_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

/// 画中画功能主页面，带有路由回调函数
class PipMainWidget extends StatelessWidget with TileDataMixin {
  final BackgroundPipWidget backgroundPipWidget = BackgroundPipWidget();

  PipMainWidget({super.key}) {
    indexWidgetProvider.define(backgroundPipWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'pip';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Pip';

  @override
  Widget build(BuildContext context) {
    Map<TileData, List<TileData>> tileData = {};
    final List<TileData> backgroundTileData = TileData.from([
      backgroundPipWidget,
    ]);
    for (var tile in backgroundTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(title: 'Background', selected: true)] =
        backgroundTileData;

    Widget pipMain = GroupDataListView(tileData: tileData);

    return pipMain;
  }
}
