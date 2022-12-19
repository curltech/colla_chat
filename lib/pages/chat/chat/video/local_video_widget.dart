import 'dart:async';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';

import 'package:colla_chat/transport/webrtc/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
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
      label: 'Video chat',
      tooltip: 'Video chat',
      icon: const Icon(Icons.video_call, color: Colors.white)),
  ActionData(
      label: 'Audio chat',
      tooltip: 'Audio chat',
      icon: const Icon(Icons.multitrack_audio_outlined, color: Colors.white)),
  ActionData(
      label: 'Screen share',
      tooltip: 'Screen share',
      icon: const Icon(Icons.screen_share, color: Colors.white)),
  ActionData(
      label: 'Media play',
      tooltip: 'Media play',
      icon: const Icon(Icons.video_file, color: Colors.white)),
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

  _openVideoMedia() async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        await localVideoRenderController.createVideoMediaRender();
        await _send(title: ContentType.video.name);
        setState(() {});
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      await localVideoRenderController.createVideoMediaRender();
      await _send(title: ContentType.video.name);
      setState(() {});
    }
  }

  _openAudioMedia() async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        await localVideoRenderController.createAudioMediaRender();
        await _send(title: ContentType.audio.name);
        setState(() {});
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      await localVideoRenderController.createAudioMediaRender();
      await _send(title: ContentType.audio.name);
      setState(() {});
    }
  }

  _openDisplayMedia() async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => ScreenSelectDialog(),
        );
        if (source != null) {
          await localVideoRenderController.createDisplayMediaRender(
              selectedSource: source);
          await _send(title: ContentType.display.name);
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
        await _send(title: ContentType.display.name);
        setState(() {});
      }
    }
  }

  _openMediaStream(MediaStream stream) async {
    var status = peerConnectionPool.status(peerId!);
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        await localVideoRenderController.createMediaStreamRender(stream);
        await _send(title: ContentType.video.name);
        setState(() {});
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('No Webrtc connected PeerConnection'));
      }
    } else if (partyType == PartyType.group.name) {
      await localVideoRenderController.createMediaStreamRender(stream);
      await _send(title: ContentType.video.name);
      setState(() {});
    }
  }

  ///发送视频通话消息
  Future<ChatMessage?> _send({required String title}) async {
    return chatMessageController.send(
        title: title, subMessageType: ChatMessageSubType.videoChat);
  }

  _close() async {
    List<AdvancedPeerConnection> pcs =
        peerConnectionsController.getAdvancedPeerConnections(peerId!);
    if (pcs.isNotEmpty) {
      for (var pc in pcs) {
        for (var render in localVideoRenderController.videoRenders.values) {
          pc.removeLocalRender(render);
        }
        await pc.negotiate();
      }
    }
    setState(() {});
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
        _openAudioMedia();
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
        actions: actionData,
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
