import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///远程视频通话窗口，显示多个小视频窗口，每个小窗口代表一个远程视频
///以及各种功能按钮
class RemoteVideoWidget extends StatefulWidget {
  const RemoteVideoWidget({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _RemoteVideoWidgetState();
  }
}

class _RemoteVideoWidgetState extends State<RemoteVideoWidget> {
  //控制面板的可见性，包括视频功能按钮和呼叫按钮
  ValueNotifier<bool> controlPanelVisible = ValueNotifier<bool>(true);

  //视频通话窗口的可见性
  ValueNotifier<int> videoViewCount = ValueNotifier<int>(0);

  //视频功能按钮对应的数据
  ValueNotifier<List<ActionData>> actionData =
      ValueNotifier<List<ActionData>>([]);

  //控制面板可见性的计时器
  Timer? _hideControlPanelTimer;

  @override
  void initState() {
    super.initState();
    _init();
    _updateView();
  }

  ///注册远程流到来或者关闭的监听器
  ///重新计算远程流的数量是否变化，决定是否重新渲染界面
  void _init() {
    p2pConferenceClientPool.addListener(_updateView);
    P2pConferenceClient? conferenceClient =
        p2pConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      conferenceClient.remotePeerMediaStreamController.addListener(_updateView);
    }
  }

  ///调整界面的显示
  Future<void> _updateView() async {
    List<ActionData> actionData = [];
    P2pConferenceClient? conferenceClient =
        p2pConferenceClientPool.conferenceClient;
    if (conferenceClient == null) {
      return;
    }
    List<PeerMediaStream> peerMediaStreams =
        conferenceClient.remotePeerMediaStreamController.peerMediaStreams;
    if (peerMediaStreams.isNotEmpty) {
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
    videoViewCount.value = peerMediaStreams.length;
  }

  ///移除远程所有的视频
  _closeAll() async {
    P2pConferenceClient? conferenceClient =
        p2pConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      conferenceClient.closeAll();
    }
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Close':
        _closeAll();
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
    var conferenceClient = p2pConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      count = conferenceClient
          .remotePeerMediaStreamController.peerMediaStreams.length;
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
          P2pConferenceClient? conferenceClient =
              p2pConferenceClientPool.conferenceClient;
          if (conferenceClient == null) {
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
                    conferenceClient.remotePeerMediaStreamController,
                onClosed: _onClosedPeerMediaStream,
              ));
        });
  }

  ///关闭单个远程视频窗口的流
  Future<void> _onClosedPeerMediaStream(PeerMediaStream peerMediaStream) async {
    P2pConferenceClient? conferenceClient =
        p2pConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      await conferenceClient.close([peerMediaStream]);
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
    p2pConferenceClientPool.removeListener(_updateView);
    P2pConferenceClient? conferenceClient =
        p2pConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      conferenceClient.remotePeerMediaStreamController
          .removeListener(_updateView);
    }
    super.dispose();
  }
}
