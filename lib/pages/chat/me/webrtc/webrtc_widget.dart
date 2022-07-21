import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../provider/app_data_provider.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listtile.dart';
import '../../../../widgets/data_bind/data_listview.dart';
import 'get_display_media_widget.dart';
import 'get_user_media_widget.dart';

final List<TileData> webrtcTileData = [
  TileData(
      icon: Icon(Icons.video_call,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'GetUserMedia',
      routeName: 'get_user_media'),
  TileData(
      icon: Icon(Icons.screen_rotation,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'GetDisplayMedia',
      routeName: 'get_display_media'),
  TileData(
      icon: Icon(Icons.generating_tokens,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'LoopBack'),
  TileData(
      icon: Icon(Icons.data_array,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'DataChannel'),
];

//设置页面，带有回退回调函数
class WebrtcWidget extends StatelessWidget with TileDataMixin {
  ///类变量，不用每次重建
  final DataListView dataListView = DataListView(tileData: webrtcTileData);

  WebrtcWidget({Key? key}) : super(key: key) {
    var indexWidgetProvider = IndexWidgetProvider.instance;
    GetUserMediaWidget getUserMediaWidget = GetUserMediaWidget();
    indexWidgetProvider.define(getUserMediaWidget);
    GetDisplayMediaWidget getDisplayMediaWidget = GetDisplayMediaWidget();
    indexWidgetProvider.define(getDisplayMediaWidget);
  }

  @override
  Widget build(BuildContext context) {
    var webrtc = KeepAliveWrapper(
        child: AppBarView(
            title: 'Webrtc', withLeading: withLeading, child: dataListView));
    return webrtc;
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'webrtc';

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'Webrtc';
}
