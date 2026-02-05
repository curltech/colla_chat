import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataListGridController extends DataListController<DataTile> {
  final RxBool gridMode = false.obs;

  //播放列表按钮
  ActionData get toggleActionData {
    return ActionData(
      label: gridMode.isTrue ? 'List' : 'Grid',
      icon: Obx(() {
        return Icon(
          gridMode.isTrue ? Icons.list : Icons.grid_on,
          color: myself.primary,
        );
      }),
      onTap: (int index, String label, {String? value}) {
        gridMode(!gridMode.value);
      },
      tooltip: AppLocalizations.t('Toggle grid mode'),
    );
  }
}

/// 列表和网格视图组件
class DataListGridView extends StatelessWidget {
  final Function(int index, String title)? onSelected;
  final DataListGridController dataListGridController;

  const DataListGridView(
      {super.key, this.onSelected, required this.dataListGridController});

  Widget _buildThumbnailWidget(BuildContext context, DataTile tile) {
    List<Widget> children = [];
    children.add(const Spacer());
    children.add(AutoSizeText(
      tile.title,
      style: const TextStyle(fontSize: AppFontSize.minFontSize),
    ));
    if (tile.subtitle != null) {
      children.add(const SizedBox(
        height: 2.0,
      ));
      children.add(AutoSizeText(
        tile.subtitle!,
        style: const TextStyle(fontSize: AppFontSize.minFontSize),
      ));
    }
    Widget thumbnail = Container(
        decoration: tile.selected ?? false
            ? BoxDecoration(border: Border.all(width: 2, color: myself.primary))
            : null,
        padding: EdgeInsets.zero,
        child: Card(
            elevation: 0.0,
            margin: EdgeInsets.zero,
            shape: const ContinuousRectangleBorder(),
            child: Stack(
              children: [
                tile.prefix ?? nilBox,
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children)
              ],
            )));

    return thumbnail;
  }

  Widget _buildThumbnailView(BuildContext context) {
    return Obx(() {
      if (dataListGridController.data.isEmpty) {
        return Container(
            alignment: Alignment.center,
            child: AutoSizeText(AppLocalizations.t('Playlist is empty'),
                style: TextStyle(fontSize: AppFontSize.maxFontSize)));
      }
      int crossAxisCount = (appDataProvider.secondaryBodyWidth / 250).ceil();
      if (dataListGridController.gridMode.isTrue) {
        return GridView.builder(
            itemCount: dataListGridController.data.length,
            //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //横轴元素个数
                crossAxisCount: crossAxisCount,
                //纵轴间距
                mainAxisSpacing: 4.0,
                //横轴间距
                crossAxisSpacing: 4.0,
                //子组件宽高长度比例
                childAspectRatio: 1),
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                  child: _buildThumbnailWidget(
                      context, dataListGridController.data[index]),
                  onTap: () {
                    dataListGridController.setCurrentIndex = index;
                    if (onSelected != null) {
                      onSelected!(
                          index, dataListGridController.data[index].title);
                    }
                  });
            });
      } else {
        return DataListView(
          onTap: (int index, String title,
              {DataTile? group, String? subtitle}) async {
            dataListGridController.setCurrentIndex = index;
            if (onSelected != null) {
              onSelected!(index, title);
            }
            return null;
          },
          itemCount: dataListGridController.data.length,
          itemBuilder: (BuildContext context, int index) {
            return dataListGridController.data[index];
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildThumbnailView(context);
  }
}
