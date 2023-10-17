import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 增加自选股的查询结果控制器
final DataListController<Share> searchShareController =
    DataListController<Share>();

/// 加自选股和分组的查询界面
class AddShareWidget extends StatefulWidget with TileDataMixin {
  AddShareWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddShareWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'add_share';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'AddShare';
}

class _AddShareWidgetState extends State<AddShareWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchTextController = TextEditingController();
  ValueNotifier<List<TileData>> tileData = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    searchShareController.clear();
    searchShareController.addListener(_updateShare);
  }

  _updateShare() {
    _buildShareTileData();
  }

  //将linkman和group数据转换从列表显示数据
  _buildShareTileData() async {
    List<Share> shares = searchShareController.data;
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
                      shareController.clear();
                      _updateShare();
                    },
                    icon: const Icon(
                      Icons.add_box_outlined,
                    )));
          }
        }

        tiles.add(tile);
      }
    }

    tileData.value = tiles;
  }

  _searchShare(String keyword) async {
    List<Share> shares = await shareService.searchShare(keyword);
    searchShareController.replaceAll(shares);
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
      ValueListenableBuilder(
          valueListenable: tileData,
          builder: (BuildContext context, List<TileData> value, Widget? child) {
            return DataListView(tileData: value);
          }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: widget.title,
        withLeading: true,
        child: _buildSearchShareView(context));
  }

  @override
  void dispose() {
    searchShareController.removeListener(_updateShare);
    super.dispose();
  }
}
