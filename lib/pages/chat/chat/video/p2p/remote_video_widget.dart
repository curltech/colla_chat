import 'dart:async';

import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
  ValueNotifier<ConferenceChatMessageController?> videoChatMessageController =
      ValueNotifier<ConferenceChatMessageController?>(
          p2pConferenceClientPool.conferenceChatMessageController);

  //控制面板的可见性，包括视频功能按钮和呼叫按钮
  ValueNotifier<bool> controlPanelVisible = ValueNotifier<bool>(true);

  //视频通话窗口的可见性
  ValueNotifier<int> videoViewCount = ValueNotifier<int>(0);

  //视频功能按钮对应的数据
  ValueNotifier<List<ActionData>> actionData =
      ValueNotifier<List<ActionData>>([]);

  P2pConferenceClient? p2pConferenceClient;

  //控制面板可见性的计时器
  Timer? _hideControlPanelTimer;

  @override
  void initState() {
    super.initState();
    _init();
    _update();
  }

  ///注册远程流到来或者关闭的监听器
  ///重新计算远程流的数量是否变化，决定是否重新渲染界面
  void _init() {
    p2pConferenceClientPool.addListener(_updateVideoChatMessageController);
    String? conferenceId = videoChatMessageController.value?.conferenceId;
    if (conferenceId != null) {
      p2pConferenceClient =
          p2pConferenceClientPool.getP2pConferenceClient(conferenceId);
      if (p2pConferenceClient != null) {
        p2pConferenceClient!.remotePeerMediaStreamController
            .addListener(_updatePeerMediaStream);
        videoViewCount.value =
            p2pConferenceClient!.remotePeerMediaStreams.length;
      }
    }
  }

  _updateVideoChatMessageController() {
    videoChatMessageController.value =
        p2pConferenceClientPool.conferenceChatMessageController;
    _update();
  }

  Future<void> _updatePeerMediaStream() async {
    if (p2pConferenceClient != null) {
      videoViewCount.value = p2pConferenceClient!.remotePeerMediaStreams.length;
    }
  }

  ///调整界面的显示
  Future<void> _update() async {
    List<ActionData> actionData = [];
    if (p2pConferenceClient == null) {
      return;
    }
    if (p2pConferenceClient!.remotePeerMediaStreams.isNotEmpty) {
      // actionData.add(
      //   ActionData(
      //       label: 'Close',
      //       tooltip: 'Close all video',
      //       icon:
      //           const Icon(Icons.closed_caption_disabled, color: Colors.white)),
      // );
    } else {
      controlPanelVisible.value = true;
    }
    this.actionData.value = actionData;
    videoViewCount.value = p2pConferenceClient!.remotePeerMediaStreams.length;
  }

  ///移除远程所有的视频，这时候还能看远程的视频
  _close() async {
    var videoChatMessageController = this.videoChatMessageController.value;
    if (videoChatMessageController == null) {
      return;
    }
    if (p2pConferenceClient != null) {
      var peerMediaStreams = p2pConferenceClient!.remotePeerMediaStreams;
      Conference? conference = videoChatMessageController.conference;
      if (conference != null) {
        p2pConferenceClientPool.removeLocalPeerMediaStream(
            conference.conferenceId, peerMediaStreams);
      }
      await p2pConferenceClient!.terminate();
    }
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Close':
        _close();
        break;
      default:
        break;
    }
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
              onPressed: _onAction,
              crossAxisCount: 1,
              labelColor: Colors.white,
            );
          }),
    );
  }

  ///切换显示按钮面板
  void _toggleActionCard() {
    int count = 0;
    var videoRoomController = p2pConferenceClientPool.p2pConferenceClient;
    if (videoRoomController != null) {
      count = videoRoomController.remotePeerMediaStreams.length;
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
                ]));
          }),
    ]);
  }

  Widget _buildGestureDetector(BuildContext context) {
    return GestureDetector(
      child: _buildVideoChatView(context),
      onDoubleTap: () {
        _toggleActionCard();
      },
    );
  }

  Widget _buildVideoChatView(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: videoViewCount,
        builder: (context, value, child) {
          var videoChatMessageController =
              this.videoChatMessageController.value;
          if (videoChatMessageController == null ||
              p2pConferenceClient == null) {
            return Center(
                child: CommonAutoSizeText(AppLocalizations.t('No conference'),
                    style: const TextStyle(color: Colors.white)));
          }
          if (value == 0) {
            return Center(
                child: CommonAutoSizeText(
                    AppLocalizations.t('No video view in current conference'),
                    style: const TextStyle(color: Colors.white)));
          }
          return Container(
              padding: const EdgeInsets.all(0.0),
              child: VideoViewCard(
                peerMediaStreamController:
                    p2pConferenceClient!.remotePeerMediaStreamController,
                onClosed: _onClosedPeerMediaStream,
                conference: videoChatMessageController.conference,
              ));
        });
  }

  ///关闭单个远程视频窗口的流
  Future<void> _onClosedPeerMediaStream(PeerMediaStream peerMediaStream) async {
    var videoChatMessageController = this.videoChatMessageController.value;
    if (videoChatMessageController == null) {
      return;
    }
    if (videoChatMessageController.conference != null) {
      //获取关联的会议
      String conferenceId = videoChatMessageController.conference!.conferenceId;
      P2pConferenceClient? p2pConferenceClient =
          p2pConferenceClientPool.getP2pConferenceClient(conferenceId);
      if (p2pConferenceClient != null) {
        //从webrtc连接中移除
        if (peerMediaStream.local) {
          await p2pConferenceClient
              .removeLocalPeerMediaStream([peerMediaStream]);
        } else {
          await p2pConferenceClient.remotePeerMediaStreamController
              .close(peerMediaStream.id!);
        }
      } else {
        logger.e('RemotePeerMediaStreamController is null');
      }
    } else {
      logger.e('No in conference');
    }
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
    if (p2pConferenceClient != null) {
      p2pConferenceClient!.remotePeerMediaStreamController
          .removeListener(_updatePeerMediaStream);
    }
    p2pConferenceClientPool.removeListener(_updateVideoChatMessageController);
    super.dispose();
  }
}
