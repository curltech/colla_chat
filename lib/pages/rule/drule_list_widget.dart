import 'package:colla_chat/pages/rule/drule.dart';
import 'package:colla_chat/pages/rule/drule_edit_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final DataListController<Drule> drulesController = DataListController<Drule>();

// drule页面
class DruleListWidget extends StatelessWidget with DataTileMixin {
  final DruleEditWidget druleEditWidget = DruleEditWidget();

  DruleListWidget({super.key}) {
    indexWidgetProvider.define(druleEditWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'drules';

  @override
  IconData get iconData => Icons.rule_folder_outlined;

  @override
  String get title => 'Drules';

  List<DataTile> _buildDrulesTileData() {
    List<Drule> drules = drulesController.data.value;
    List<DataTile> tiles = [];
    if (drules.isNotEmpty) {
      int i = 0;
      for (var drule in drules) {
        var title = drule.name;
        var subtitle = drule.id;
        DataTile tile = DataTile(
            selected: drulesController.currentIndex.value == i,
            title: title ?? '',
            subtitle: subtitle,
            routeName: 'drule_edit');
        List<DataTile> slideActions = [];
        DataTile deleteSlideAction = DataTile(
            title: 'Delete',
            prefix: Icons.remove,
            onTap: (int index, String label, {String? subtitle}) async {
              drulesController.setCurrentIndex = index;
              drulesController.delete(index: index);
            });
        slideActions.add(deleteSlideAction);
        DataTile editSlideAction = DataTile(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String label, {String? subtitle}) async {
              drulesController.setCurrentIndex = index;
              indexWidgetProvider.push('drule_edit');
            });
        slideActions.add(editSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
        i++;
      }
    }
    return tiles;
  }

  Future<bool?> _onTap(int index, String title,
      {String? subtitle, DataTile? group}) async {
    drulesController.setCurrentIndex = index;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var druleList = Obx(() {
      var tiles = _buildDrulesTileData();
      return DataListView(
        onTap: _onTap,
        itemCount: tiles.length,
        itemBuilder: (BuildContext context, int index) {
          return tiles[index];
        },
      );
    });

    var druleListWidget = AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        child: druleList);

    return druleListWidget;
  }
}
