import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///远程视频通话窗口，显示多个小视频窗口，每个小窗口代表一个远程视频
///以及各种功能按钮
class RemoteVideoWidget extends StatefulWidget {
  final VideoMode videoMode;

  const RemoteVideoWidget({
    Key? key,
    required this.videoMode,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RemoteVideoWidgetState();
  }
}

class _RemoteVideoWidgetState extends State<RemoteVideoWidget> {
  //当前的群编号，说明正在群中聊天
  String? groupPeerId;

  //当前的联系人编号和名称，说明正在一对一聊天
  String? peerId;
  String? name;

  //当前的通话房间，房间是临时组建的一组联系人，互相聊天和视频通话
  //如果当前的群存在的话，房间的人在群的联系人中选择，否则在所有的联系人中选择
  Room? room;

  //对应的房间中远程视频的存放地
  VideoRoomRenderController? videoRoomController;

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
    videoChatMessageController.addListener(_update);
    _init();
  }

  _update() {
    if (mounted) {
      _buildActionDataAndVisible();
    }
  }

  _init() async {
    _buildActionDataAndVisible();
    if (widget.videoMode == VideoMode.conferencing) {
      return;
    }
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      logger
          .e('videoMode is ${widget.videoMode.name}, but chatSummary is null');
      return;
    }
    peerId = chatSummary.peerId!;
    name = chatSummary.name!;
    var partyType = chatSummary.partyType;
    if (partyType == PartyType.group.name) {
      groupPeerId = chatSummary.peerId!;
    }
    //当前的视频通话的邀请消息，如果存在，获取房间信息
    ChatMessage? chatMessage = videoChatMessageController.chatMessage;
    if (chatMessage != null) {
      String content = chatMessage.content!;
      content = chatMessageService.recoverContent(content);
      Map json = JsonUtil.toJson(content);
      room = Room.fromJson(json);
      //获取房间对应的远程视频通话的房间视频控制器
      videoRoomController =
          videoRoomRenderPool.getVideoRoomRenderController(room!.roomId!);
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
    var videoRoomController =
        videoRoomRenderPool.getVideoRoomRenderController(room!.roomId!);
    if (videoRoomController != null) {
      videoRoomController.close();
    }
  }

  ///切换显示按钮面板
  void _toggleActionCard() {
    int count = 0;
    var videoRoomController = videoRoomRenderPool.videoRoomRenderController;
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
    VideoRoomRenderController? videoRoomRenderController =
        videoRoomRenderPool.getVideoRoomRenderController(room!.roomId!);
    if (videoRoomRenderController == null) {
      return Container();
    }
    return Container(
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(0.5),
        child: VideoViewCard(
          videoRenderController: videoRoomRenderController,
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
    var videoRoomRenderController =
        videoRoomRenderPool.videoRoomRenderController;
    if (videoRoomRenderController != null) {
      videoRoomRenderController.removeListener(_update);
    }
    super.dispose();
  }
}
