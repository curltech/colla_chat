import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_participant_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_room_widget.dart';
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
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatefulWidget with TileDataMixin {
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
  final LiveKitSfuParticipantWidget liveKitSfuParticipantWidget =
      LiveKitSfuParticipantWidget();

  MeWidget({super.key}) {
    indexWidgetProvider.define(collectionListView);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(webrtcWidget);
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(mediaWidget);
    indexWidgetProvider.define(systemAlertWindowWidget);
    indexWidgetProvider.define(contactWidget);
    indexWidgetProvider.define(openVpnWidget);
    indexWidgetProvider.define(liveKitSfuRoomWidget);
    indexWidgetProvider.define(liveKitSfuParticipantWidget);
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
  State<StatefulWidget> createState() => _MeWidgetState();
}

class _MeWidgetState extends State<MeWidget> {
  final ValueNotifier<bool> developerSwitch =
      ValueNotifier<bool>(myself.peerProfile.developerSwitch);

  @override
  void initState() {
    super.initState();
    myself.addListener(_update);
  }

  _update() {
    developerSwitch.value = myself.peerProfile.developerSwitch;
  }

  List<TileData> _buildMeTileData(BuildContext context) {
    List<TileDataMixin> mixins = [
      widget.settingWidget,
      widget.collectionListView,
    ];

    if (platformParams.mobile) {
      mixins.add(widget.contactWidget);
      if (myself.peerProfile.vpnSwitch) {
        mixins.add(widget.openVpnWidget);
      }
      if (platformParams.android) {
        if (developerSwitch.value) {
          mixins.addAll([
            widget.systemAlertWindowWidget,
          ]);
        }
      }
    }
    if (developerSwitch.value) {
      mixins.addAll([
        widget.webrtcWidget,
        widget.webViewWidget,
        widget.mediaWidget,
        widget.liveKitSfuRoomWidget,
      ]);
    }
    List<TileData> meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = false;
      tile.selected = false;
    }

    return meTileData;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ValueListenableBuilder(
        valueListenable: developerSwitch,
        builder: (BuildContext context, bool developerSwitch, Widget? child) {
          List<TileData> meTileData = _buildMeTileData(context);
          return DataListView(tileData: meTileData);
        });

    var me = AppBarView(
        title: widget.title,
        child: Column(
            children: <Widget>[const MeHeadWidget(), Expanded(child: child)]));
    return me;
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    super.dispose();
  }
}
