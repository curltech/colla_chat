import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
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

final List<ActionData> actionData = [
  ActionData(
      label: 'Minimize',
      tooltip: 'Minimize view',
      icon: const Icon(Icons.zoom_in_map)),
  ActionData(
      label: 'Video chat',
      tooltip: 'Video chat',
      icon: const Icon(Icons.video_call)),
  ActionData(
      label: 'Audio chat',
      tooltip: 'Audio chat',
      icon: const Icon(Icons.multitrack_audio_outlined)),
  ActionData(
      label: 'Screen share',
      tooltip: 'Screen share',
      icon: const Icon(Icons.screen_share)),
  ActionData(
      label: 'Media play',
      tooltip: 'Media play',
      icon: const Icon(Icons.video_file)),
  ActionData(
      label: 'Camera switch',
      tooltip: 'Camera switch',
      icon: const Icon(Icons.cameraswitch)),
  ActionData(
      label: 'Microphone',
      tooltip: 'Microphone switch',
      icon: const Icon(Icons.mic_rounded)),
  ActionData(
      label: 'Speaker',
      tooltip: 'Speaker switch',
      icon: const Icon(Icons.speaker_phone)),
];

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
  String? clientId;
  String partyType = PartyType.linkman.name;

  //final focusNode = FocusNode();
  ValueNotifier<bool> actionCardVisible =
      ValueNotifier<bool>(false); // position to false;
  Timer? _hidePanelTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
      clientId = chatSummary.clientId;
      partyType = chatSummary.partyType!;
    } else {
      logger.e('chatSummary is null');
    }
  }



  _open(
      {MediaStream? stream,
      bool videoMedia = false,
      bool audioMedia = false,
      bool displayMedia = false}) async {
    if (partyType == PartyType.linkman.name) {
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(peerId!, clientId: clientId);
      if (advancedPeerConnection != null &&
          advancedPeerConnection.status == PeerConnectionStatus.connected) {
        await localMediaController.createVideoRender(
            stream: stream,
            videoMedia: videoMedia,
            audioMedia: audioMedia,
            displayMedia: displayMedia);
        if (audioMedia) {
          await _send(title: ContentType.audio.name);
        } else if (displayMedia) {
          await _send(title: ContentType.display.name);
        } else {
          await _send(title: ContentType.video.name);
        }
        setState(() {});
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      await localMediaController.createVideoRender(
          stream: stream,
          videoMedia: videoMedia,
          audioMedia: audioMedia,
          displayMedia: displayMedia);
      if (audioMedia) {
        await _send(title: ContentType.audio.name);
      } else if (displayMedia) {
        await _send(title: ContentType.display.name);
      } else {
        await _send(title: ContentType.video.name);
      }
      setState(() {});
    }
  }

  ///发送视频通话消息
  Future<ChatMessage?> _send({required String title}) async {
    return chatMessageController.send(
        title: title, subMessageType: ChatMessageSubType.videoChat);
  }

  _close() {
    localMediaController.close();
    chatMessageController.chatView = ChatView.text;
    setState(() {});
  }

  ///视频视图
  Widget _buildVideoViewCard(BuildContext context) {
    if (peerId == null) {
      return Container();
    }
    if (partyType == PartyType.linkman.name) {
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(peerId!, clientId: clientId);
      if (advancedPeerConnection != null &&
          advancedPeerConnection.status == PeerConnectionStatus.connected) {
        return VideoViewCard(
          videoRenders: localMediaController.localVideoRenders().values.toList(),
          color: widget.color,
        );
      }
    } else if (partyType == PartyType.group.name) {
      return VideoViewCard(
        videoRenders: localMediaController.localVideoRenders().values.toList(),
        color: widget.color,
      );
    }
    linkmanService.findAvatarImageWidget(peerId!);
    return Container();
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Video chat':
        _open(videoMedia: true);
        break;
      case 'Audio chat':
        _open(audioMedia: true);
        break;
      case 'Screen share':
        _open(displayMedia: true);
        break;
      case 'Media play':
        _open();
        break;
      case 'Camera switch':
        break;
      case 'Microphone':
        break;
      case 'Speaker':
        break;
      default:
        break;
    }
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 180;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: actionData,
        height: height,
        onPressed: _onAction,
        crossAxisCount: 4,
      ),
    );
  }

  ///切换显示按钮面板
  void _toggleActionCard() {
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
                    padding: const EdgeInsets.all(15.0),
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
                  ))
                ]));
          })
    ]);
  }

  Widget _buildGestureDetector(BuildContext context) {
    return GestureDetector(
      child: _buildVideoViewCard(context),
      onTap: () {
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
    //focusNode.dispose();
    super.dispose();
  }
}
