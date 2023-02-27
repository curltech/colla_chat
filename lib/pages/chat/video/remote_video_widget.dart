import 'dart:async';

import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/video/video_view_card.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///远程视频通话窗口，显示多个小视频窗口，每个小窗口代表一个远程视频
///以及各种功能按钮
class RemoteVideoWidget extends StatefulWidget {
  final VideoChatMessageController videoChatMessageController;

  const RemoteVideoWidget({Key? key, required this.videoChatMessageController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RemoteVideoWidgetState();
  }
}

class _RemoteVideoWidgetState extends State<RemoteVideoWidget> {
  //控制面板的可见性，包括视频功能按钮和呼叫按钮
  ValueNotifier<bool> controlPanelVisible = ValueNotifier<bool>(true);

  //视频功能按钮对应的数据
  ValueNotifier<List<ActionData>> actionData =
      ValueNotifier<List<ActionData>>([]);

  //控制面板可见性的计时器
  Timer? _hideControlPanelTimer;

  @override
  void initState() {
    super.initState();
    //视频通话的消息存放地
    widget.videoChatMessageController.addListener(_update);
    String? conferenceId = widget.videoChatMessageController.conferenceId;
    if (conferenceId != null) {
      RemoteVideoRenderController? remoteVideoRenderController =
          videoConferenceRenderPool
              .getRemoteVideoRenderController(conferenceId);
      if (remoteVideoRenderController != null) {
        remoteVideoRenderController.addListener(_update);
      }
    }
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  _close() async {
    var conferenceId = widget.videoChatMessageController.conferenceId;
    if (conferenceId != null) {
      var remoteVideoRenderController = videoConferenceRenderPool
          .getRemoteVideoRenderController(conferenceId);
      if (remoteVideoRenderController != null) {
        remoteVideoRenderController.close();
      }
    }
  }

  ///切换显示按钮面板
  void _toggleActionCard() {
    int count = 0;
    var videoRoomController =
        videoConferenceRenderPool.remoteVideoRenderController;
    if (videoRoomController != null) {
      count = videoRoomController.videoRenders.length;
    }
    if (count == 0) {
      controlPanelVisible.value = true;
    } else {
      if (_hideControlPanelTimer != null) {
        _hideControlPanelTimer?.cancel();
        controlPanelVisible.value = false;
        _hideControlPanelTimer = null;
      } else {
        controlPanelVisible.value = true;
        _hideControlPanelTimer?.cancel();
        _hideControlPanelTimer = Timer(const Duration(seconds: 15), () {
          if (!mounted) return;
          controlPanelVisible.value = false;
          _hideControlPanelTimer = null;
        });
      }
    }
  }

  ///控制面板
  Widget _buildControlPanel(BuildContext context) {
    return Column(children: [
      const Spacer(),
      ValueListenableBuilder<bool>(
          valueListenable: controlPanelVisible,
          builder: (context, value, child) {
            return Visibility(
                visible: controlPanelVisible.value,
                child: Column(children: [
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
    String? conferenceId = widget.videoChatMessageController.conferenceId;
    RemoteVideoRenderController? remoteVideoRenderController;
    if (conferenceId != null) {
      remoteVideoRenderController = videoConferenceRenderPool
          .getRemoteVideoRenderController(conferenceId);
    }
    if (remoteVideoRenderController == null) {
      return const Center(
          child: Text('No conference', style: TextStyle(color: Colors.white)));
    }
    return Container(
        padding: const EdgeInsets.all(0.0),
        color: Colors.black,
        child: VideoViewCard(
          videoRenderController: remoteVideoRenderController,
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
    String? conferenceId = widget.videoChatMessageController.conferenceId;
    if (conferenceId != null) {
      var remoteVideoRenderController = videoConferenceRenderPool
          .getRemoteVideoRenderController(conferenceId);
      if (remoteVideoRenderController != null) {
        remoteVideoRenderController.removeListener(_update);
      }
    }
    super.dispose();
  }
}
