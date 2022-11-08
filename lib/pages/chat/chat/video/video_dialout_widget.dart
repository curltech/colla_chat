import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/blank_widget.dart';
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
      label: '视频通话', tooltip: '视频通话', icon: const Icon(Icons.video_call)),
  ActionData(
      label: '音频通话',
      tooltip: '音频通话',
      icon: const Icon(Icons.multitrack_audio_outlined)),
  ActionData(
      label: '屏幕共享', tooltip: '屏幕共享', icon: const Icon(Icons.screen_share)),
  ActionData(
      label: '媒体播放', tooltip: '媒体播放', icon: const Icon(Icons.video_file)),
  ActionData(
      label: '镜头切换', tooltip: '镜头切换', icon: const Icon(Icons.cameraswitch)),
  ActionData(
      label: '显示背景',
      tooltip: '显示背景',
      icon: const Icon(Icons.photo_camera_back)),
  ActionData(
      label: '麦克风开关', tooltip: '麦克风开关', icon: const Icon(Icons.mic_rounded)),
  ActionData(
      label: '扬声器开关', tooltip: '扬声器开关', icon: const Icon(Icons.speaker_phone)),
];

///视频通话拨出的窗口
class VideoDialOutWidget extends StatefulWidget {
  final Color? color;

  const VideoDialOutWidget({Key? key, this.color}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoDialOutWidgetState();
  }
}

class _VideoDialOutWidgetState extends State<VideoDialOutWidget> {
  String? peerId;
  String? name;
  String? clientId;
  String partyType = PartyType.linkman.name;
  double opacity = 0.5;
  OverlayEntry? overlayEntry;

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

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      chatMessageController.viewIndex = 1;
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(builder: (context) {
      return Align(
        alignment: Alignment.topRight,
        child: WidgetUtil.buildCircleButton(
            padding: const EdgeInsets.all(15.0),
            backgroundColor: appDataProvider.themeData!.colorScheme.primary,
            onPressed: () {
              _closeOverlayEntry();
            },
            child:
                const Icon(size: 32, color: Colors.white, Icons.zoom_out_map)),
      );
    });
    Overlay.of(context)!.insert(overlayEntry!);
    chatMessageController.viewIndex = 0;
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
        title: title, subMessageType: ChatSubMessageType.videoChat);
  }

  _close() {
    localMediaController.close();
    chatMessageController.viewIndex = 0;
    setState(() {});
  }

  Widget _buildVideoViewCard(BuildContext context) {
    if (peerId == null) {
      return const BlankWidget();
    }
    if (partyType == PartyType.linkman.name) {
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(peerId!, clientId: clientId);
      if (advancedPeerConnection != null &&
          advancedPeerConnection.status == PeerConnectionStatus.connected) {
        return VideoViewCard(
          controller: localMediaController,
          color: widget.color,
        );
      }
    } else if (partyType == PartyType.group.name) {
      return VideoViewCard(
        controller: localMediaController,
        color: widget.color,
      );
    }
    return const BlankWidget();
  }

  _opacity() {
    if (opacity == 1) {
      opacity = 0.5;
    } else {
      opacity = 1;
    }
    setState(() {});
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (index) {
      case 0:
        _open(videoMedia: true);
        break;
      case 1:
        _open(audioMedia: true);
        break;
      case 2:
        _open(displayMedia: true);
        break;
      case 3:
        _open();
        break;
      case 4:
        break;
      case 5:
        _opacity();
        break;
      case 6:
        break;
      case 7:
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

  Widget _buildDialOutView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _minimize(context);
                },
                child: const Icon(Icons.zoom_in_map, size: 32),
              ),
              const SizedBox(
                width: 25,
              ),
              Text(AppLocalizations.t('Waiting accept inviting...'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black)),
            ],
          )),
      Expanded(
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            myself.avatarImage!,
            Text(name ?? ''),
          ]))),
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
      )),
    ]);
  }

  Widget _build(BuildContext context) {
    return Stack(children: [
      Opacity(opacity: opacity, child: _buildVideoViewCard(context)),
      _buildDialOutView(context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
