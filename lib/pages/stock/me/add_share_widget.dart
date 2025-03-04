import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 加自选股和分组的查询界面
class AddShareWidget extends StatelessWidget with TileDataMixin {
  AddShareWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'add_share';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'AddShare';

  @override
  String? get information => null;

  final TextEditingController searchTextController = TextEditingController();

  /// 增加自选股的查询结果
  final RxList<Share> shares = <Share>[].obs;
  final RxList<TileData> tileData = <TileData>[].obs;

  //将linkman和group数据转换从列表显示数据
  Future<List<TileData>> _buildShareTileData() async {
    List<TileData> tiles = [];
    if (shares.isNotEmpty) {
      for (var share in shares) {
        var name = share.name;
        var tsCode = share.tsCode;
        TileData tile = TileData(
          title: name!,
          subtitle: tsCode,
          selected: false,
        );
        String subscription = myShareController.subscription.value;
        if (tsCode != null) {
          bool contain = subscription.contains(tsCode);
          if (!contain) {
            tile = TileData(
                title: name,
                subtitle: tsCode,
                selected: false,
                suffix: IconButton(
                  onPressed: () async {
                    await myShareController.add(share);
                    tileData.value = await _buildShareTileData();
                  },
                  icon: Icon(
                    Icons.add_box_outlined,
                    color: myself.primary,
                  ),
                ),
                onTap: (int index, String title, {String? subtitle}) async {
                  await multiKlineController.put(tsCode);
                  multiKlineController.replaceAll([tsCode]);
                  indexWidgetProvider.push('stockline_chart');
                });
          }
        }

        tiles.add(tile);
      }
    }

    return tiles;
  }

  _searchShare(String keyword) async {
    if (keyword.isNotEmpty) {
      shares.value = await remoteShareService.sendSearchShare(keyword);
      tileData.value = await _buildShareTileData();
    }
  }

  Widget _buildSearchShareView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          child: CommonAutoSizeTextFormField(
            controller: searchTextController,
            keyboardType: TextInputType.text,
            prefixIcon: IconButton(
              onPressed: () {
                searchTextController.text = '';
              },
              icon: Icon(
                Icons.clear,
                color: myself.primary,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                _searchShare(searchTextController.text);
              },
              icon: Icon(
                Icons.search,
                color: myself.primary,
              ),
            ),
          )),
      Expanded(child: Obx(() {
        return DataListView(
          itemCount: tileData.length,
          itemBuilder: (BuildContext context, int index) {
            return tileData[index];
          },
        );
      })),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title, withLeading: true, child: _buildSearchShareView(context));
  }
}
