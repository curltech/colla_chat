import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/webrtc/data_channel_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/get_display_media_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/get_user_media_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

final List<TileData> webrtcTileData = [
  TileData(
      prefix: Icon(Icons.video_call,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'GetUserMedia',
      routeName: 'get_user_media'),
  TileData(
      prefix: Icon(Icons.screen_rotation,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'GetDisplayMedia',
      routeName: 'get_display_media'),
  TileData(
      prefix: Icon(Icons.generating_tokens,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'LoopBack'),
  TileData(
      prefix: Icon(Icons.data_array,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'DataChannel',
      routeName: 'data_channel'),
  TileData(
      prefix: Icon(Icons.video_call,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'PeerConnection',
      routeName: 'peer_connection'),
];

//设置页面，带有回退回调函数
class WebrtcWidget extends StatelessWidget with TileDataMixin {
  ///类变量，不用每次重建
  final DataListView dataListView = DataListView(tileData: webrtcTileData);

  WebrtcWidget({Key? key}) : super(key: key) {
    GetUserMediaWidget getUserMediaWidget = GetUserMediaWidget();
    indexWidgetProvider.define(getUserMediaWidget);
    GetDisplayMediaWidget getDisplayMediaWidget = GetDisplayMediaWidget();
    indexWidgetProvider.define(getDisplayMediaWidget);
    DataChannelWidget dataChannelWidget = DataChannelWidget();
    indexWidgetProvider.define(dataChannelWidget);
    PeerConnectionWidget peerConnectionWidget = PeerConnectionWidget();
    indexWidgetProvider.define(peerConnectionWidget);
  }

  @override
  Widget build(BuildContext context) {
    var webrtc = KeepAliveWrapper(
        child: AppBarView(
            title: Text(AppLocalizations.t('')),
            withLeading: withLeading,
            child: dataListView));
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
