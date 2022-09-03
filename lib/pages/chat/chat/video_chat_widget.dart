import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video_view_card.dart';
import 'package:flutter/material.dart';

import '../../../provider/app_data_provider.dart';
import '../../../widgets/common/action_card.dart';
import '../../../widgets/common/simple_widget.dart';
import '../../../widgets/data_bind/data_listtile.dart';
import 'chat_message_widget.dart';
import 'controller/local_media_controller.dart';

final List<TileData> actionTileData = [
  TileData(title: '镜头切换', icon: const Icon(Icons.cameraswitch)),
  TileData(title: '麦克风开关', icon: const Icon(Icons.mic_rounded)),
  TileData(title: '扬声器开关', icon: const Icon(Icons.speaker_phone)),
];

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
      chatMessageController.index = 1;
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Align(
            alignment: Alignment.topRight,
            child: WidgetUtil.buildCircleButton(
                padding: const EdgeInsets.all(15.0),
                backgroundColor: appDataProvider.themeData!.colorScheme.primary,
                onPressed: () {
                  _closeOverlayEntry();
                },
                child: const Icon(
                    size: 32, color: Colors.white, Icons.zoom_out_map)),
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

  Future<void> _onAction(int index, String name) async {
    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        break;
      default:
        break;
    }
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 100;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: ActionCard(
        actions: actionTileData,
        height: height,
        onPressed: _onAction,
      ),
    );
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Column(children: [
      Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.black.withAlpha(128),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _minimize(context);
                },
                child: const Icon(Icons.zoom_in_map, size: 16),
              ),
              WidgetUtil.buildCircleButton(
                  onPressed: () {
                    _close();
                  },
                  elevation: 2.0,
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(
                    Icons.call_end,
                    size: 16.0,
                    color: Colors.white,
                  )),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      actionVisible = true;
                    });
                  },
                  child: const Icon(Icons.add_circle, size: 16),
                ),
              ),
            ],
          )),
      _buildVideoViewCard(context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildVideoChatView(context),
      Visibility(
          visible: actionVisible,
          child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildActionCard(context)))
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
