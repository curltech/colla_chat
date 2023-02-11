import 'dart:async';

import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///远程视频通话窗口，显示多个小视频窗口，每个小窗口代表一个对方，其中一个是自己
///以及各种功能按钮
class RemoteVideoWidget extends StatefulWidget {
  final String roomId;

  const RemoteVideoWidget({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RemoteVideoWidgetState();
  }
}

class _RemoteVideoWidgetState extends State<RemoteVideoWidget> {
  ValueNotifier<bool> actionCardVisible = ValueNotifier<bool>(true);
  Timer? _hidePanelTimer;

  @override
  void initState() {
    super.initState();
    var videoRoomController = videoRoomRenderPool.videoRoomController;
    if (videoRoomController != null) {
      videoRoomController.addListener(_update);
    }
  }

  _update() {
    _toggleActionCard();
  }

  List<ActionData> _buildActionData() {
    List<ActionData> actionData = [];

    return actionData;
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 70;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: _buildActionData(),
        height: height,
        //width: 320,
        onPressed: _onAction,
        crossAxisCount: 4,
        labelColor: Colors.white,
      ),
    );
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      default:
        break;
    }
  }

  _close() async {
    var videoRoomController = videoRoomRenderPool.videoRoomController;
    if (videoRoomController != null) {
      videoRoomController.close();
    }
  }

  ///切换显示按钮面板
  void _toggleActionCard() {
    int count = 0;
    var videoRoomController = videoRoomRenderPool.videoRoomController;
    if (videoRoomController != null) {
      count = videoRoomController.videoRenders.length;
    }
    if (count == 0) {
      actionCardVisible.value = true;
    } else {
      if (_hidePanelTimer != null) {
        _hidePanelTimer?.cancel();
        actionCardVisible.value = false;
        _hidePanelTimer = null;
      } else {
        actionCardVisible.value = true;
        _hidePanelTimer?.cancel();
        _hidePanelTimer = Timer(const Duration(seconds: 15), () {
          if (!mounted) return;
          actionCardVisible.value = false;
          _hidePanelTimer = null;
        });
      }
    }
  }

  ///控制面板
  Widget _buildControlPanel(BuildContext context) {
    return Column(children: [
      const Spacer(),
      ValueListenableBuilder<bool>(
          valueListenable: actionCardVisible,
          builder: (context, value, child) {
            return Visibility(
                visible: actionCardVisible.value,
                child: Column(children: [
                  _buildActionCard(context),
                  Center(
                      child: Container(
                    padding: const EdgeInsets.all(25.0),
                    child: WidgetUtil.buildCircleButton(
                      onPressed: () {
                        _close();
                      },
                      elevation: 2.0,
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(15.0),
                      child: const Icon(
                        Icons.call_end,
                        size: 48.0,
                        color: Colors.white,
                      ),
                    ),
                  )),
                ]));
          })
    ]);
  }

  Widget _buildGestureDetector(BuildContext context) {
    return GestureDetector(
      child: _buildVideoChatView(context),
      onLongPress: () {
        _toggleActionCard();
        //focusNode.requestFocus();
      },
    );
  }

  Widget _buildVideoChatView(BuildContext context) {
    VideoRoomRenderController? videoRoomController =
        videoRoomRenderPool.getVideoRoomController(widget.roomId);
    if (videoRoomController == null) {
      return Container();
    }
    return Container(
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(0.5),
        child: VideoViewCard(
          videoRenderController: videoRoomController,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildGestureDetector(context),
      _buildControlPanel(context),
    ]);
  }

  @override
  void dispose() {
    var videoRoomController = videoRoomRenderPool.videoRoomController;
    if (videoRoomController != null) {
      videoRoomController.removeListener(_update);
    }
    super.dispose();
  }
}
