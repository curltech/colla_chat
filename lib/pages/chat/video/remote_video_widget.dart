import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///远程视频通话窗口，显示多个小视频窗口，每个小窗口代表一个远程视频
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

  //视频邀请消息和回执的控制器
  VideoChatMessageController videoChatMessageController =
      VideoChatMessageController();

  @override
  void initState() {
    super.initState();
    //视频通话的消息存放地
    videoChatMessageController.addListener(_update);
    _init();
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

  ///本界面是在聊天界面转过来，所以当前chatSummary是必然存在的，
  ///当前chatMessage在选择了视频邀请消息后，也是存在的
  ///如果chatMessage不存在，表明是想开始发起新的linkman或者group会议
  ///初始化是根据当前的视频邀请消息chatMessage来决定的，无论是发起还是接收邀请
  ///也可以根据当前会议来决定的，适用于群和会议模式
  ///如果没有设置，表明是新的会议
  _init() async {
    _buildActionDataAndVisible();
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    //先设置当前视频聊天控制器的邀请消息为null
    videoChatMessageController.setChatMessage(null, chatSummary: chatSummary);
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    partyType = chatSummary.partyType;
    if (partyType == PartyType.linkman.name) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
    } else if (partyType == PartyType.group.name) {
      groupPeerId = chatSummary.peerId!;
      name = chatSummary.name!;
    } else if (partyType == PartyType.conference.name) {
      _initConference(chatSummary);
    }
    ChatMessage? chatMessage = chatMessageController.current;
    if (chatMessage == null) {
      logger.e('current chatMessage is not exist');
    } else {
      if (partyType == PartyType.linkman.name) {
        _initLinkman(chatMessage, chatSummary: chatSummary);
      } else if (partyType == PartyType.group.name) {
        _initGroup(chatMessage, chatSummary: chatSummary);
      }
    }
  }

  ///linkman模式的初始化
  _initLinkman(ChatMessage chatMessage,
      {required ChatSummary chatSummary}) async {
    //进入视频界面是先选择了视频邀请消息
    if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
      conference = videoChatMessageController.conference;
      name = conference!.name;
      conferenceName = conference!.name;
      //conferenceController.current = conference;
      videoChatMessageController.setChatMessage(chatMessage,
          chatSummary: chatSummary);
    }
  }

  _initGroup(ChatMessage chatMessage,
      {required ChatSummary chatSummary}) async {
    //进入视频界面是先选择了视频邀请消息
    if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
      conferenceId = chatMessage.messageId!;
      conference = await conferenceService.findOneByConferenceId(conferenceId!);
      if (conference != null) {
        conferenceName = conference!.name;
        conferenceController.current = conference;
        videoChatMessageController.setChatMessage(chatMessage,
            chatSummary: chatSummary);
      }
    }
  }

  _initConference(ChatSummary chatSummary) async {
    conferenceId = chatSummary.peerId!;
    conference = await conferenceService.findOneByConferenceId(conferenceId!);
    if (conference != null) {
      name = conference!.name;
      conferenceName = conference!.name;
      conferenceController.current = conference;
      //检查当前消息，进入视频界面是先选择了视频邀请消息，或者没有
      ChatMessage? chatMessage =
          await chatMessageService.findOriginByMessageId(conferenceId!);
      if (chatMessage != null) {
        //进入视频界面是先选择了视频邀请消息
        if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
          videoChatMessageController.setChatMessage(chatMessage);
        }
      }
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
