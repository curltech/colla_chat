import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/webrtc/data_channel_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/get_display_media_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/get_user_media_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//webrtc页面
class WebrtcWidget extends StatelessWidget with TileDataMixin {
  late final Widget child;

  WebrtcWidget({Key? key}) : super(key: key) {
    GetUserMediaWidget getUserMediaWidget = const GetUserMediaWidget();
    indexWidgetProvider.define(getUserMediaWidget);
    GetDisplayMediaWidget getDisplayMediaWidget = const GetDisplayMediaWidget();
    indexWidgetProvider.define(getDisplayMediaWidget);
    DataChannelWidget dataChannelWidget = DataChannelWidget();
    indexWidgetProvider.define(dataChannelWidget);
    PeerConnectionWidget peerConnectionWidget = PeerConnectionWidget();
    indexWidgetProvider.define(peerConnectionWidget);
    List<TileDataMixin> mixins = [
      getUserMediaWidget,
      getDisplayMediaWidget,
      dataChannelWidget,
      peerConnectionWidget,
    ];
    final List<TileData> meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = true;
    }
    child = DataListView(tileData: meTileData);
  }

  @override
  Widget build(BuildContext context) {
    var webrtc = KeepAliveWrapper(
        child: AppBarView(
            title: title,
            withLeading: withLeading,
            child: child));
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
