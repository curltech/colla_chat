import 'package:colla_chat/pages/game/majiang/back/majiang_widget.dart';
import 'package:colla_chat/pages/game/majiang/majiang_18m_widget.dart';
import 'package:colla_chat/pages/game/model/meta_modeller_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 游戏功能主页面，带有路由回调函数
class GameMainWidget extends StatelessWidget with TileDataMixin {
  final Majiang18mWidget majiang18mWidget = Majiang18mWidget();
  final MetaModellerWidget metaModellerWidget = MetaModellerWidget();

  GameMainWidget({super.key}) {
    indexWidgetProvider.define(majiang18mWidget);
    indexWidgetProvider.define(metaModellerWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'game_main';

  @override
  IconData get iconData => Icons.games_outlined;

  @override
  String get title => 'Game';

  @override
  Widget build(BuildContext context) {
    final List<TileData> gameTileData = TileData.from([
      majiang18mWidget,
      metaModellerWidget,
    ]);
    for (var tile in gameTileData) {
      tile.dense = false;
      tile.selected = false;
    }

    Widget gameMain = DataListView(
      itemBuilder: (BuildContext context, int index) {
        return gameTileData[index];
      },
      itemCount: gameTileData.length,
    );

    return gameMain;
  }
}
