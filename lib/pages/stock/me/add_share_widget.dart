import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

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

  final TextEditingController _searchTextController = TextEditingController();

  /// 增加自选股的查询结果
  List<Share> shares = [];
  ValueNotifier<List<TileData>> tileData = ValueNotifier<List<TileData>>([]);

  //将linkman和group数据转换从列表显示数据
  _buildShareTileData() async {
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
        String subscription = shareService.subscription;
        if (tsCode != null) {
          bool contain = subscription.contains(tsCode);
          if (!contain) {
            tile = TileData(
                title: name,
                subtitle: tsCode,
                selected: false,
                suffix: IconButton(
                  onPressed: () async {
                    await shareService.add(share);
                    _buildShareTileData();
                  },
                  icon: const Icon(
                    Icons.add_box_outlined,
                  ),
                ),
                onTap: (int index, String title, {String? subtitle}) async {
                  Share? share = await shareService.findShare(tsCode);
                  String name = share?.name ?? '';
                  multiStockLineController.replaceAll([tsCode]);
                  multiStockLineController.put(tsCode, name);
                  indexWidgetProvider.push('stockline_chart');
                });
          }
        }

        tiles.add(tile);
      }
    }

    tileData.value = tiles;
  }

  _searchShare(String keyword) async {
    if (keyword.isNotEmpty) {
      shares = await remoteShareService.sendSearchShare(keyword);
      await _buildShareTileData();
    }
  }

  Widget _buildSearchShareView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          child: CommonAutoSizeTextFormField(
            controller: _searchTextController,
            keyboardType: TextInputType.text,
            suffixIcon: IconButton(
              onPressed: () {
                _searchShare(_searchTextController.text);
              },
              icon: Icon(
                Icons.search,
                color: myself.primary,
              ),
            ),
          )),
      Expanded(
          child: ValueListenableBuilder(
              valueListenable: tileData,
              builder:
                  (BuildContext context, List<TileData> value, Widget? child) {
                return DataListView(
                  itemCount: value.length,
                  itemBuilder: (BuildContext context, int index) {
                    return value[index];
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
