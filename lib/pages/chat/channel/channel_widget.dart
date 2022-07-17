import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/widget_mixin.dart';
import '../../../widgets/data_bind/data_listtile.dart';
import '../../../widgets/data_bind/data_listview.dart';

final List<TileData> mockTileData = [
  TileData(
      icon: const Icon(Icons.collections),
      title: '李志群',
      routeName: '/chat/collection'),
  TileData(
      icon: const Icon(Icons.settings),
      title: '胡百水',
      routeName: '/chat/setting'),
];

//频道的页面
class ChannelWidget extends StatelessWidget with TileDataMixin {
  late final List<TileData> channelTileData = mockTileData;

  ChannelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body = DataListView(tileData: channelTileData);
    return AppBarView(
      title: AppLocalizations.instance.text(title),
      child: body,
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
