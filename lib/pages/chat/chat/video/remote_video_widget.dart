import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:flutter/material.dart';

///远程视频通话窗口，显示多个小视频窗口，每个小窗口代表一个对方，其中一个是自己
///以及各种功能按钮
class RemoteVideoWidget extends StatefulWidget {
  const RemoteVideoWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RemoteVideoWidgetState();
  }
}

class _RemoteVideoWidgetState extends State<RemoteVideoWidget> {
  bool actionVisible = false;

  @override
  void initState() {
    super.initState();
  }

  _close() {
    chatMessageController.chatView = ChatView.text;
    setState(() {});
  }

  Widget _buildVideoViewCard(BuildContext context) {
    return VideoViewCard(
      videoRenderController: peerConnectionsController,
    );
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(5.0),
          color: Colors.black.withOpacity(0.5),
          child: Row(
            children: [
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    actionVisible = !actionVisible;
                  });
                },
                child: const Icon(Icons.add_circle, size: 24),
              ),
            ],
          )),
      Expanded(child: _buildVideoViewCard(context)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildVideoChatView(context),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
