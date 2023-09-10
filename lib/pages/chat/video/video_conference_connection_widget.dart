import 'package:colla_chat/pages/chat/video/video_conference_track_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///会议池的会议的连接列表显示界面
class VideoConferenceConnectionWidget extends StatelessWidget
    with TileDataMixin {
  final VideoConferenceTrackWidget videoConferenceTrackWidget =
      const VideoConferenceTrackWidget();

  VideoConferenceConnectionWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(videoConferenceTrackWidget);
  }

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
            titleTail: connectionState?.name.substring(22),
            subtitle: peerId,
            isThreeLine: false,
            onTap: (int index, String title, {String? subtitle}) {
              peerConnectionNotifier.value = peerConnection;
              indexWidgetProvider.push('video_conference_track');
            },
            routeName: null);

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
