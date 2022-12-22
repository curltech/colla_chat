import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///视频通话的流程
///1.发起方发起视频通话请求，激活拨出窗口；
///2.接收方接收视频通话请求，激活拨入对话框；
///3.接收方选择接受或者拒绝，如果接受，发送回执，关闭对话框，激活本地视频并加入连接，打开通话窗口
///4.接收方选择拒绝，发送回执，关闭对话框
///5.发起方收到回执，如果是接受回执，关闭拨出窗口，激活本地视频并加入连接，打开通话窗口，等待远程视频流到来，显示
///6.发起方收到回执，如果是拒绝回执，关闭拨出窗口
///7.接收方等待远程视频流到来，显示
///8.如果发起方在接收回执到来前，自己主动终止请求，执行挂断操作，设置挂断标志，对远程流不予接受

///本地视频通话显示和拨出的窗口，显示多个小视频窗口，每个小窗口代表一个对方，其中一个是自己
///以及各种功能按钮
class LocalVideoWidget extends StatefulWidget {
  final Color? color;

  const LocalVideoWidget({Key? key, this.color}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LocalVideoWidgetState();
  }
}

class _LocalVideoWidgetState extends State<LocalVideoWidget> {
  String? peerId;
  String? name;
  String partyType = PartyType.linkman.name;

  ValueNotifier<bool> actionCardVisible = ValueNotifier<bool>(true);
  Timer? _hidePanelTimer;

  @override
  void initState() {
    super.initState();
    _init();
    localVideoRenderController.addListener(_update);
  }

  _init() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
      partyType = chatSummary.partyType!;
    } else {
      logger.e('chatSummary is null');
    }
  }

  _update() {
    _toggleActionCard();
  }

  List<ActionData> _buildActionData() {
    List<ActionData> actionData = [];
    if (localVideoRenderController.videoChatRender == null) {
      actionData.add(
        ActionData(
            label: 'Video chat',
            tooltip: 'Video chat',
            icon: const Icon(Icons.video_call, color: Colors.white)),
      );
      actionData.add(
        ActionData(
            label: 'Audio chat',
            tooltip: 'Audio chat',
            icon: const Icon(Icons.multitrack_audio_outlined,
                color: Colors.white)),
      );
    }
    actionData.add(
      ActionData(
          label: 'Screen share',
          tooltip: 'Screen share',
          icon: const Icon(Icons.screen_share, color: Colors.white)),
    );
    // actionData.add(
    //   ActionData(
    //       label: 'Media play',
    //       tooltip: 'Media play',
    //       icon: const Icon(Icons.video_file, color: Colors.white)),
    // );

    return actionData;
  }

  ///弹出界面，选择参与者，返回房间
  Future<Room> _buildRoom() async {
    return Room('');
  }

  _openVideoMedia({bool video = true}) async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      ///还需要检查本连接是否已经在room中，如果在，不需要发送邀请，增加完render，重新协商就可以了
      if (status == PeerConnectionStatus.connected) {
        var videoChatRender = localVideoRenderController.videoChatRender;
        if (videoChatRender == null) {
          if (video) {
            await localVideoRenderController.createVideoMediaRender();
          } else {
            await localVideoRenderController.createAudioMediaRender();
          }
          var videoRoomController = videoRoomPool.videoRoomController;
          bool connected = false;
          if (videoRoomController != null) {
            List<AdvancedPeerConnection> pcs =
                videoRoomController.getAdvancedPeerConnections(peerId!);
            if (pcs.isNotEmpty) {
              for (var pc in pcs) {
                connected = true;
                pc.negotiate();
              }
            }
          }
          if (!connected) {
            if (video) {
              await _sendLinkman(title: ContentType.video.name);
            } else {
              await _sendLinkman(title: ContentType.audio.name);
            }
            setState(() {});
          }
        }
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      if (video) {
        await localVideoRenderController.createVideoMediaRender();
        Room room = await _buildRoom();
        await _sendGroup(title: ContentType.video.name, room: room);
      } else {
        await localVideoRenderController.createAudioMediaRender();
        Room room = await _buildRoom();
        await _sendGroup(title: ContentType.audio.name, room: room);
      }
      setState(() {});
    }
  }

  _openDisplayMedia() async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        final source = await DialogUtil.show<DesktopCapturerSource>(
          context: context,
          builder: (context) => Dialog(child: ScreenSelectDialog()),
        );
        if (source != null) {
          await localVideoRenderController.createDisplayMediaRender(
              selectedSource: source);
          await _sendLinkman(title: ContentType.display.name);
          setState(() {});
        }
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      final source = await showDialog<DesktopCapturerSource>(
        context: context,
        builder: (context) => ScreenSelectDialog(),
      );
      if (source != null) {
        await localVideoRenderController.createDisplayMediaRender(
            selectedSource: source);
        Room room = await _buildRoom();
        await _sendGroup(title: ContentType.display.name, room: room);
        setState(() {});
      }
    }
  }

  _openMediaStream(MediaStream stream) async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        await localVideoRenderController.createMediaStreamRender(stream);
        await _sendLinkman(title: ContentType.video.name);
        setState(() {});
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      await localVideoRenderController.createMediaStreamRender(stream);
      Room room = await _buildRoom();
      await _sendGroup(title: ContentType.video.name, room: room);
      setState(() {});
    }
  }

  ///发送linkman视频通邀请话消息,此时消息无data
  Future<ChatMessage?> _sendLinkman({required String title}) async {
    return chatMessageController.send(
        title: title, subMessageType: ChatMessageSubType.videoChat);
  }

  ///发送group视频通邀请话消息,此时消息必须有data,包含Room信息
  ///需要群发给room里面的参与者，而不是group的所有成员
  Future<ChatMessage?> _sendGroup(
      {required String title, required Room room}) async {
    String json = JsonUtil.toJsonString(room);
    return chatMessageController.sendText(
        title: title,
        message: json,
        subMessageType: ChatMessageSubType.videoChat,
        peerIds: room.participants);
  }

  _close() async {
    localVideoRenderController.close();
  }

  ///视频视图
  Widget _buildVideoView(BuildContext context) {
    if (peerId == null) {
      return Container();
    }
    if (partyType == PartyType.linkman.name) {
      var status = peerConnectionPool.status(peerId!);
      if (status == PeerConnectionStatus.connected) {
        return VideoViewCard(
          color: widget.color,
          videoRenderController: localVideoRenderController,
        );
      }
    } else if (partyType == PartyType.group.name) {
      return VideoViewCard(
        videoRenderController: localVideoRenderController,
        color: widget.color,
      );
    }
    linkmanService.findAvatarImageWidget(peerId!);
    return Container();
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Video chat':
        _openVideoMedia();
        break;
      case 'Audio chat':
        _openVideoMedia(video: false);
        break;
      case 'Screen share':
        _openDisplayMedia();
        break;
      case 'Media play':
        //_openMediaStream(stream);
        break;
      default:
        break;
    }
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

  ///切换显示按钮面板
  void _toggleActionCard() {
    int count = localVideoRenderController.videoRenders.length;
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
      child: _buildVideoView(context),
      onLongPress: () {
        _toggleActionCard();
        //focusNode.requestFocus();
      },
    );
  }

  Widget _buildLocalVideo(BuildContext context) {
    return Stack(children: [
      _buildGestureDetector(context),
      _buildControlPanel(context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildLocalVideo(context);
  }

  @override
  void dispose() {
    localVideoRenderController.removeListener(_update);
    super.dispose();
  }
}
