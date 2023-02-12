import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/pages/chat/linkman/group_linkman_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

///视频通话的流程，适用单个通话和群
///1.发起方在本地通话窗口发起视频通话请求（缺省会打开本地的视频或者音频，但不会打开屏幕共享），
///实际是先打开本地流（还没有加入连接中，重新协商），
///然后一个视频通话的邀请消息发送出去，邀请消息的编号也是房间号，以后通过消息编号可以重新加入
///2.接收方接收视频通话请求，屏幕顶部激活拨入对话框；
///3.接收方选择接受或者拒绝，无论接受或者拒绝，先发送回执消息，关闭对话框，
///如果是接受，打开本地视频或者音频，并加入本地连接，打开本地通话窗口，打开远程通话窗口，等待远程视频流到来，开始通话
///4.接收方如果选择拒绝，以后可以通过点击视频通话请求消息重新进入本地通话窗口，然后再次加入视频，
///5.发起方收到回执，如果是是接受回执，关闭本地通话窗口，本地流加入连接中，重新协商，打开远程通话窗口，
///等待协商结束，远程视频流到来，开始通话
///6.发起方收到回执，如果是拒绝回执，关闭本地通话窗口和本地流，回到文本通话窗口
///7.任何方主动终止请求，发起视频通话终止请求，执行挂断操作，设置挂断标志，关闭本地流和远程流
///8.任何方接受到视频通话终止请求消息，执行挂断操作，设置挂断标志，关闭本地流和远程流，发起重新协商

///本地视频通话显示和拨出的窗口，显示多个本地视频，音频和屏幕共享的小视频窗口
///各种功能按钮，可以切换视频和音频，添加屏幕共享视频，此时需要发起重新协商
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
    videoChatMessageController.addListener(_update);
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
    } else if (localVideoRenderController.video) {
      actionData.add(
        ActionData(
            label: 'Audio chat',
            tooltip: 'Audio chat',
            icon: const Icon(Icons.multitrack_audio_outlined,
                color: Colors.white)),
      );
    } else {
      actionData.add(
        ActionData(
            label: 'Video chat',
            tooltip: 'Video chat',
            icon: const Icon(Icons.video_call, color: Colors.white)),
      );
    }
    if (localVideoRenderController.videoChatRender != null) {
      actionData.add(
        ActionData(
            label: 'Screen share',
            tooltip: 'Screen share',
            icon: const Icon(Icons.screen_share, color: Colors.white)),
      );
    }
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
    List<String> participants = [myself.peerId!];
    if (partyType == PartyType.linkman.name) {
      participants.add(peerId!);
    } else if (partyType == PartyType.group.name) {
      await DialogUtil.show(
          context: context,
          builder: (BuildContext context) {
            return GroupLinkmanWidget(
              onSelected: (List<String> peerIds) {
                participants.addAll(peerIds);
                Navigator.pop(context, participants);
              },
              selected: [],
              groupPeerId: peerId!,
            );
          });
    }
    var uuid = const Uuid();
    String roomId = uuid.v4();
    return Room(roomId, participants: participants);
  }

  _openVideoMedia({bool video = true}) async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status != PeerConnectionStatus.connected) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
        return;
      }
    }

    ///本地视频不存在，可以直接创建，并发送视频邀请消息，否则根据情况觉得是否音视频切换
    var videoChatRender = localVideoRenderController.videoChatRender;
    if (videoChatRender == null) {
      if (video) {
        await localVideoRenderController.createVideoMediaRender();
      } else {
        await localVideoRenderController.createAudioMediaRender();
      }
    } else {
      if (video) {
        if (!localVideoRenderController.video) {
          await localVideoRenderController.createVideoMediaRender();
        }
      } else {
        if (localVideoRenderController.video) {
          await localVideoRenderController.createAudioMediaRender();
        }
      }
    }
    videoChatRender = localVideoRenderController.videoChatRender;

    ChatMessage? chatMessage = videoChatMessageController.chatMessage;
    if (chatMessage == null) {
      //当前视频消息为空，则创建房间，发送视频通话邀请消息
      //由消息的接收方同意后直接重新协商
      var room = await _buildRoom();
      logger.i('current video chatMessage is null, create room ${room.roomId}');
      if (video) {
        chatMessage = await _sendVideoChatMessage(
            contentType: ContentType.video.name, room: room);
      } else {
        chatMessage = await _sendVideoChatMessage(
            contentType: ContentType.audio.name, room: room);
      }
      videoChatMessageController.chatMessage = chatMessage;
      videoRoomRenderPool.createVideoRoomRenderController(room);
    } else {
      //当前视频消息不为空，则有同意回执的直接重新协商
      var messageId = chatMessage.messageId!;
      logger.i('current video chatMessage $messageId');
      var videoRoomRenderController =
          videoRoomRenderPool.getVideoRoomRenderController(messageId);
      if (videoRoomRenderController != null) {
        List<AdvancedPeerConnection> pcs =
            videoRoomRenderController.getAdvancedPeerConnections(peerId!);
        if (pcs.isNotEmpty) {
          for (var pc in pcs) {
            pc.negotiate();
          }
        }
      }
    }
  }

  _openDisplayMedia() async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status != PeerConnectionStatus.connected) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
        return;
      }
    }

    ChatMessage? chatMessage = videoChatMessageController.chatMessage;
    if (chatMessage == null) {
      DialogUtil.error(context, content: AppLocalizations.t('No room'));
      return;
    }
    final source = await DialogUtil.show<DesktopCapturerSource>(
      context: context,
      builder: (context) => Dialog(child: ScreenSelectDialog()),
    );
    if (source != null) {
      await localVideoRenderController.createDisplayMediaRender(
          selectedSource: source);
      var messageId = chatMessage.messageId!;
      var videoRoomRenderController =
          videoRoomRenderPool.getVideoRoomRenderController(messageId);
      if (videoRoomRenderController != null) {
        List<AdvancedPeerConnection> pcs =
            videoRoomRenderController.getAdvancedPeerConnections(peerId!);
        if (pcs.isNotEmpty) {
          for (var pc in pcs) {
            pc.negotiate();
          }
        }
      }
    }
  }

  _openMediaStream(MediaStream stream) async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status != PeerConnectionStatus.connected) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
        return;
      }
    }

    ChatMessage? chatMessage = videoChatMessageController.chatMessage;
    if (chatMessage == null) {
      DialogUtil.error(context, content: AppLocalizations.t('No room'));
      return;
    }
    await localVideoRenderController.createMediaStreamRender(stream);
    var messageId = chatMessage.messageId!;
    var videoRoomController =
        videoRoomRenderPool.getVideoRoomRenderController(messageId);
    if (videoRoomController != null) {
      List<AdvancedPeerConnection> pcs =
          videoRoomController.getAdvancedPeerConnections(peerId!);
      if (pcs.isNotEmpty) {
        for (var pc in pcs) {
          pc.negotiate();
        }
      }
    }
  }

  ///发送group视频通邀请话消息,此时消息必须有content,包含Room信息
  ///需要群发给room里面的参与者，而不是group的所有成员
  Future<ChatMessage?> _sendVideoChatMessage(
      {required String contentType, required Room room}) async {
    ChatMessage? chatMessage = await chatMessageController.send(
        title: contentType,
        content: room,
        messageId: room.roomId,
        subMessageType: ChatMessageSubType.videoChat,
        peerIds: room.participants);
    if (chatMessage != null) {
      logger.i('send video chatMessage ${chatMessage.messageId}');
    }

    return chatMessage;
  }

  _close() async {
    localVideoRenderController.close();
    videoChatMessageController.chatMessage = null;
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
