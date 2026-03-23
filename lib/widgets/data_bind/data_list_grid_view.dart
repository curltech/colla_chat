import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

class DataListGridController extends DataListController<DataTile> {
  final ValueNotifier<bool> gridMode = ValueNotifier<bool>(false);

  //播放列表按钮
  ActionData get toggleActionData {
    return ActionData(
      label: gridMode.value ? 'List' : 'Grid',
      icon: ValueListenableBuilder(
          valueListenable: gridMode,
          builder: (context, value, _) {
            return Icon(
              gridMode.value ? Icons.list : Icons.grid_on,
              color: myself.primary,
            );
          }),
      onTap: (int index, String label, {String? value}) {
        gridMode.value = !gridMode.value;
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
    return ListenableBuilder(
        listenable: Listenable.merge([
          dataListGridController.gridMode,
          dataListGridController.data,
          dataListGridController.currentIndex
        ]),
        builder: (context, _) {
          if (dataListGridController.data.value.isEmpty) {
            return nilBox;
          }

          if (dataListGridController.gridMode.value) {
            return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              // constraints.maxWidth, constraints.maxHeight
              int crossAxisCount = (constraints.maxWidth / 250).floor();
              return GridView.builder(
                  itemCount: dataListGridController.data.value.length,
                  //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      //横轴元素个数
                      crossAxisCount: crossAxisCount,
                      //纵轴间距
                      mainAxisSpacing: 2.0,
                      //横轴间距
                      crossAxisSpacing: 2.0,
                      //子组件宽高长度比例
                      childAspectRatio: 1),
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                        child: _buildThumbnailWidget(
                            context, dataListGridController.data.value[index]),
                        onTap: () {
                          dataListGridController.current?.selected = false;
                          dataListGridController.data.value[index].selected =
                              true;
                          dataListGridController.setCurrentIndex = index;
                          String title =
                              dataListGridController.data.value[index].title;
                          if (onSelected != null) {
                            onSelected!(index,
                                dataListGridController.data.value[index].title);
                          }
                          dataListGridController.data.value[index].onTap
                              ?.call(index, title);
                        });
                  });
            });
          } else {
            return DataListView(
              onTap: (int index, String title,
                  {DataTile? group, String? subtitle}) async {
                dataListGridController.current?.selected = false;
                dataListGridController.data.value[index].selected = true;
                dataListGridController.setCurrentIndex = index;
                if (onSelected != null) {
                  onSelected!(index, title);
                }
                return null;
              },
              itemCount: dataListGridController.data.value.length,
              itemBuilder: (BuildContext context, int index) {
                return dataListGridController.data.value[index];
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
