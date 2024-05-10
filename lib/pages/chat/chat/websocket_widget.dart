import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_participant_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_room_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_view.dart';
import 'package:colla_chat/pages/chat/me/contact_widget.dart';
import 'package:colla_chat/pages/chat/me/me_head_widget.dart';
import 'package:colla_chat/pages/chat/me/media/media_widget.dart';
import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/android_system_alert_window_widget.dart';
import 'package:colla_chat/pages/chat/me/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_info_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_map_launcher_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/chat/me/poem/poem_widget.dart';
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
class WebSocketWidget extends StatefulWidget with TileDataMixin {
  WebSocketWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'web_socket';

  @override
  IconData get iconData => Icons.webhook_outlined;

  @override
  String get title => 'WebSocket';

  @override
  State<StatefulWidget> createState() => _WebSocketWidgetState();
}

class _WebSocketWidgetState extends State<WebSocketWidget> {
  @override
  void initState() {
    super.initState();
    myself.addListener(_update);
  }

  _update() {}

  List<TileData> _buildMeTileData(BuildContext context) {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<TileData> meTileData = _buildMeTileData(context);
    Widget child = DataListView(tileData: meTileData);

    var me = AppBarView(title: widget.title, child: child);
    return me;
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    super.dispose();
  }
}
