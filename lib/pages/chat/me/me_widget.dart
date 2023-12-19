import 'package:colla_chat/pages/chat/chat/video/livekit/widget/livekit_sfu_room_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_view.dart';
import 'package:colla_chat/pages/chat/me/contact_widget.dart';
import 'package:colla_chat/pages/chat/me/me_head_widget.dart';
import 'package:colla_chat/pages/chat/me/media/media_widget.dart';
import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/android_system_alert_window_widget.dart';
import 'package:colla_chat/pages/chat/me/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/webrtc_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget with TileDataMixin {
  final PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget();
  final CollectionListView collectionListView = CollectionListView();
  final SettingWidget settingWidget = SettingWidget();
  final WebrtcWidget webrtcWidget = WebrtcWidget();
  final MediaWidget mediaWidget = MediaWidget();
  final PlatformWebViewWidget webViewWidget = PlatformWebViewWidget();
  final OpenVpnWidget openVpnWidget = const OpenVpnWidget();
  final ContactWidget contactWidget = const ContactWidget();
  final SystemAlertWindowWidget systemAlertWindowWidget =
      const SystemAlertWindowWidget();
  final LiveKitSfuRoomWidget liveKitSfuRoomWidget = LiveKitSfuRoomWidget();

  late final List<TileData> meTileData;

  MeWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(collectionListView);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(webrtcWidget);
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(mediaWidget);
    if (platformParams.mobile) {
      indexWidgetProvider.define(contactWidget);
      indexWidgetProvider.define(openVpnWidget);
      if (platformParams.android) {
        indexWidgetProvider.define(systemAlertWindowWidget);
      }
    }
    indexWidgetProvider.define(liveKitSfuRoomWidget);
    List<TileDataMixin> mixins = [
      settingWidget,
      collectionListView,
      webrtcWidget,
      webViewWidget,
      mediaWidget,
    ];
    if (platformParams.mobile) {
      mixins.addAll([
        contactWidget,
        openVpnWidget,
      ]);
      if (platformParams.android) {
        mixins.addAll([
          systemAlertWindowWidget,
        ]);
      }
    }
    mixins.add(liveKitSfuRoomWidget);
    meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = false;
      tile.selected = false;
    }
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Me';

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: meTileData);
    var me = AppBarView(
        title: title,
        child: Column(
            children: <Widget>[const MeHeadWidget(), Expanded(child: child)]));
    return me;
  }
}
