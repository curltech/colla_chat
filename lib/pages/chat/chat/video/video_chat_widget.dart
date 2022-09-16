import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';

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
  bool actionVisible = false;
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
  }

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      chatMessageController.index = 2;
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(builder: (context) {
      return Align(
        alignment: Alignment.topRight,
        child: WidgetUtil.buildCircleButton(
            padding: const EdgeInsets.all(15.0),
            backgroundColor: appDataProvider.themeData.colorScheme.primary,
            onPressed: () {
              _closeOverlayEntry();
            },
            child:
                const Icon(size: 32, color: Colors.white, Icons.zoom_out_map)),
      );
    });
    Overlay.of(context)!.insert(overlayEntry!);
    chatMessageController.index = 0;
  }

  _close() {
    localMediaController.close();
    chatMessageController.index = 0;
    setState(() {});
  }

  Widget _buildVideoViewCard(BuildContext context) {
    return VideoViewCard(
      controller: peerConnectionsController,
    );
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(5.0),
          color: Colors.black.withOpacity(0.5),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _minimize(context);
                },
                child: const Icon(Icons.zoom_in_map, size: 24),
              ),
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
