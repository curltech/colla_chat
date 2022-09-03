import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video_view_card.dart';
import 'package:flutter/material.dart';

///视频通话窗口，显示多个小视频窗口，每个小窗口代表一个对方，其中一个是自己
///以及各种功能按钮
class VideoChatWidget extends StatefulWidget {
  const VideoChatWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoChatWidgetState();
  }
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildVideoViewCard(BuildContext context) {
    return VideoViewCard(
      controller: peerConnectionsController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoViewCard(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
