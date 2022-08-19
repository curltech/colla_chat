import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video_view_card.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'controller/local_media_controller.dart';

///视频通话窗口，显示多个小视频窗口，每个小窗口代表一个对方，其中一个是自己
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  VideoChatWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoChatWidgetState();
  }

  @override
  bool get withLeading => false;

  @override
  String get routeName => 'video_chat';

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'VideoChat';
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  String? peerId;
  String? name;
  String? clientId;

  @override
  void initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
    ChatMessage? chatMessage = localMediaController.chatMessage;
    if (chatMessage != null) {
      peerId = localMediaController.peerId;
      name = localMediaController.name;
      clientId = localMediaController.clientId;
    } else {
      logger.e('no video chat chatMessage');
    }
  }

  _update() {
    setState(() {});
  }

  Future<Widget> _buildLocalVideoView() async {
    Widget empty = Container();
    ChatMessage? chatMessage = localMediaController.chatMessage;
    if (chatMessage == null) {
      return empty;
    }
    var peerId = this.peerId;
    if (peerId == null) {
      return empty;
    }
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection == null) {
      return empty;
    }
    PeerConnectionStatus? status = advancedPeerConnection.status;
    if (status != PeerConnectionStatus.connected) {
      return empty;
    }
    PeerVideoRender render = localMediaController.userRender;
    await render.createUserMedia();
    await render.bindRTCVideoRender();
    advancedPeerConnection.addRender(render);
    Widget videoView = render.createVideoView(mirror: true);

    return videoView;
  }

  Widget _buildVideoViewCard(BuildContext context) {
    if (peerId != null) {
      return const VideoViewCard();
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        child: Stack(children: [
          _buildVideoViewCard(context),
        ]));
  }

  @override
  void dispose() {
    peerConnectionsController.removeListener(_update);
    super.dispose();
  }
}
