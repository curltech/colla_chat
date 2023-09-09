import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///会议池的会议的连接列表显示界面
class VideoConferenceConnectionWidget extends StatelessWidget
    with TileDataMixin {
  const VideoConferenceConnectionWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_conference_connection';

  @override
  IconData get iconData => Icons.connecting_airports_outlined;

  @override
  String get title => 'Video conference connection';

  List<TileData> _buildConnectionTileData(BuildContext context) {
    P2pConferenceClient? p2pConferenceClient =
        p2pConferenceClientPool.p2pConferenceClient;
    List<TileData> tiles = [];
    if (p2pConferenceClient != null) {
      List<AdvancedPeerConnection> peerConnections =
          p2pConferenceClient.peerConnections;
      for (AdvancedPeerConnection peerConnection in peerConnections) {
        var peerId = peerConnection.peerId;
        var name = peerConnection.name;
        var connectionState = peerConnection.connectionState;
        var initiator = peerConnection.basePeerConnection.initiator;
        TileData tile = TileData(
            prefix: initiator == true
                ? const Icon(
                    Icons.light_mode,
                    color: Colors.yellow,
                  )
                : const Icon(
                    Icons.light_mode,
                    color: Colors.grey,
                  ),
            title: name,
            titleTail: connectionState?.name,
            subtitle: peerId,
            isThreeLine: true,
            onTap: (int index, String title, {String? subtitle}) {},
            routeName: 'peer_connection_show');

        tiles.add(tile);
      }
    }
    return tiles;
  }

  Widget _buildConnectionListView(BuildContext context) {
    var connectionView = DataListView(
      tileData: _buildConnectionTileData(context),
    );

    return connectionView;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: _buildConnectionListView(context),
    );
  }
}
