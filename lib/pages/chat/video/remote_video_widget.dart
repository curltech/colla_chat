import 'dart:async';

import 'package:colla_chat/entity/chat/conference.dart';
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
  String? partyType;

  //或者会议名称，或者群名称，或者联系人名称
  String? name;

  //当前的会议编号，说明正在群中聊天
  String? conferenceId;
  String? conferenceName;

  //当前的群编号，说明正在群中聊天
  String? groupPeerId;

  //当前的联系人编号和名称，说明正在一对一聊天
  String? peerId;

  //当前的通话房间，房间是临时组建的一组联系人，互相聊天和视频通话
  //如果当前的群存在的话，房间的人在群的联系人中选择，否则在所有的联系人中选择
  Conference? conference;

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
    RemoteVideoRenderController? remoteVideoRenderController =
        videoConferenceRenderPool
            .getRemoteVideoRenderController(conference!.conferenceId);
    if (remoteVideoRenderController != null) {
      remoteVideoRenderController.addListener(_update);
    }
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  _buildActionDataAndVisible() {
    List<ActionData> actionData = [];

    this.actionData.value = actionData;
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 80;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: ValueListenableBuilder<List<ActionData>>(
          valueListenable: actionData,
          builder: (context, value, child) {
            return DataActionCard(
              actions: value,
              height: height,
              //width: 320,
              onPressed: _onAction,
              crossAxisCount: 4,
              labelColor: Colors.white,
            );
          }),
    );
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      default:
        break;
    }
  }

  _close() async {
    var remoteVideoRenderController = videoConferenceRenderPool
        .getRemoteVideoRenderController(conference!.conferenceId);
    if (remoteVideoRenderController != null) {
      remoteVideoRenderController.close();
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
    RemoteVideoRenderController? remoteVideoRenderController =
        videoConferenceRenderPool
            .getRemoteVideoRenderController(conference!.conferenceId);
    if (remoteVideoRenderController == null) {
      return Container();
    }
    return Container(
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(0.5),
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
    var remoteVideoRenderController = videoConferenceRenderPool
        .getRemoteVideoRenderController(conference!.conferenceId);
    if (remoteVideoRenderController != null) {
      remoteVideoRenderController.removeListener(_update);
    }
    super.dispose();
  }
}
