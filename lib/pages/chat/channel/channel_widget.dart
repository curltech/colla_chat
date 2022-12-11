import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';


final List<TileData> mockTileData = [
  TileData(
      prefix: const Icon(Icons.collections),
      title: '李志群',
      routeName: '/chat/collection'),
  TileData(
      prefix: const Icon(Icons.settings),
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
      title: Text(AppLocalizations.t(title)),
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
