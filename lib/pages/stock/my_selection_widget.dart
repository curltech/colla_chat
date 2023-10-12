import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/add_share_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 自选股的控制器
final DataListController<Share> shareController = DataListController<Share>();

///自选股和分组的查询界面
class ShareSelectionWidget extends StatefulWidget with TileDataMixin {
  final AddShareWidget addShareWidget = AddShareWidget();

  ShareSelectionWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(addShareWidget);
  }

  @override
  State<StatefulWidget> createState() => _ShareSelectionWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'my_selection';

  @override
  IconData get iconData => Icons.featured_play_list_outlined;

  @override
  String get title => 'MySelection';
}

class _ShareSelectionWidgetState extends State<ShareSelectionWidget>
    with TickerProviderStateMixin {
  final ValueNotifier<List<TileData>> _shareTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<int> _currentTab = ValueNotifier<int>(0);

  @override
  initState() {
    super.initState();
    shareController.addListener(_updateShare);
  }

  _updateShare() {
    _buildShareTileData();
  }

  /// 将linkman和group数据转换从列表显示数据
  _buildShareTileData() {
    List<Share> shares = shareController.data;
    List<TileData> tiles = [];
    if (shares.isNotEmpty) {
      for (var share in shares) {
        var name = share.name;
        var tsCode = share.tsCode;
        TileData tile = TileData(
            title: name!, subtitle: tsCode, selected: false, routeName: '');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Remove',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Share:')} ${share.name}${AppLocalizations.t(' is removed')}');
              }
            });
        slideActions.add(deleteSlideAction);

        tiles.add(tile);
      }
    }
    _shareTileData.value = tiles;
  }

  _onTapShare(int index, String title, {TileData? group, String? subtitle}) {}

  Widget _buildShareListView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _shareTileData,
        builder: (context, value, child) {
          return DataListView(
            tileData: value,
            onTap: _onTapShare,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add share'),
        onPressed: () {
          indexWidgetProvider.push('add_share');
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
    ];
    return AppBarView(
        title: widget.title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: _buildShareListView(context));
  }

  @override
  void dispose() {
    shareController.removeListener(_updateShare);
    super.dispose();
  }
}
