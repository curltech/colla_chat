import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../widgets/common/data_group_listview.dart';
import '../../../widgets/common/data_listtile.dart';
import '../../../widgets/common/widget_mixin.dart';

final Map<TileData, List<TileData>> mockTileData = {
  TileData(title: '未知'): [
    TileData(
        icon: const Icon(Icons.collections),
        title: '李志群',
        routeName: '/chat/collection'),
    TileData(
        icon: const Icon(Icons.settings),
        title: '胡百水',
        routeName: '/chat/setting'),
  ]
};

//频道的页面
class ChannelWidget extends StatelessWidget with TileDataMixin {
  late final Map<TileData, List<TileData>> channelTileData = mockTileData;

  ChannelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      title: Text(
        AppLocalizations.instance.text(title),
      ),
      actions: [],
    );
    var body = GroupDataListView(tileData: channelTileData);
    return Scaffold(
      appBar: appBar,
      //列表
      body: body,
    );
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'channel';

  @override
  Icon get icon => const Icon(Icons.point_of_sale_sharp);

  @override
  String get title => 'Channel';
}
