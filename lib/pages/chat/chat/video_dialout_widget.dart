import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/pages/chat/chat/video_view_card.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/blank_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../service/chat/chat.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/base_peer_connection.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import '../../../widgets/common/action_card.dart';
import '../../../widgets/common/image_widget.dart';
import '../../../widgets/common/simple_widget.dart';
import '../../../widgets/data_bind/data_listtile.dart';
import 'chat_message_widget.dart';
import 'controller/local_media_controller.dart';

///视频通话的流程
///1.发起方发起视频通话请求，激活拨出窗口；
///2.接收方接收视频通话请求，激活拨入对话框；
///3.接收方选择接受或者拒绝，如果接受，发送回执，关闭对话框，激活本地视频并加入连接，打开通话窗口
///4.接收方选择拒绝，发送回执，关闭对话框
///5.发起方收到回执，如果是接受回执，关闭拨出窗口，激活本地视频并加入连接，打开通话窗口，等待远程视频流到来，显示
///6.发起方收到回执，如果是拒绝回执，关闭拨出窗口
///7.接收方等待远程视频流到来，显示
///8.如果发起方在接收回执到来前，自己主动终止请求，执行挂断操作，设置挂断标志，对远程流不予接受

final List<TileData> actionTileData = [
  TileData(title: '视频通话', icon: const Icon(Icons.video_call)),
  TileData(title: '音频通话', icon: const Icon(Icons.multitrack_audio_outlined)),
  TileData(title: '屏幕共享', icon: const Icon(Icons.screen_share)),
  TileData(title: '媒体播放', icon: const Icon(Icons.video_file)),
  TileData(title: '镜头切换', icon: const Icon(Icons.cameraswitch)),
  TileData(title: '显示背景', icon: const Icon(Icons.photo_camera_back)),
  TileData(title: '麦克风开关', icon: const Icon(Icons.mic_rounded)),
  TileData(title: '扬声器开关', icon: const Icon(Icons.speaker_phone)),
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
  late final String peerId;
  String? name;
  String? clientId;
  double opacity = 0.5;
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    localMediaController.addListener(_receive);
    _init();
  }

  _init() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
      clientId = chatSummary.clientId;
    } else {
      logger.e('chatSummary is null');
    }
  }

  ///收到回执
  _receive() async {
    ChatMessage? chatReceipt = videoChatReceiptController.chatReceipt;
    if (chatReceipt != null) {
      String? status = chatReceipt.status;
      String? subMessageType = chatReceipt.subMessageType;
      if (subMessageType != null) {
        logger.i('received videoChat chatReceipt status: $status');
        if (subMessageType == ChatSubMessageType.chatReceipt.name) {
          if (status == ChatReceiptType.agree.name) {
            var peerId = chatReceipt.senderPeerId!;
            var clientId = chatReceipt.senderClientId!;
            AdvancedPeerConnection? advancedPeerConnection =
                peerConnectionPool.getOne(
              peerId,
              clientId: clientId,
            );
            if (advancedPeerConnection != null) {
              Map<String, PeerVideoRender> videoRenders =
                  localMediaController.videoRenders();
              for (var render in videoRenders.values) {
                await advancedPeerConnection.addRender(render);
              }
              advancedPeerConnection.negotiate();
              peerConnectionsController.clear();
              peerConnectionsController.add(peerId, clientId: clientId);
              chatMessageController.index = 2;
            }
          } else if (status == ChatReceiptType.reject.name) {
            var videoRenders = localMediaController.videoRenders();
            if (videoRenders.isNotEmpty) {
              for (var videoRender in videoRenders.values) {
                localMediaController.close(id: videoRender.id);
              }
            }
            chatMessageController.index = 0;
          }
        }
      }
    }
  }

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      chatMessageController.index = 1;
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Align(
            alignment: Alignment.topRight,
            child: WidgetUtil.buildCircleButton(
                padding: const EdgeInsets.all(15.0),
                backgroundColor: appDataProvider.themeData!.colorScheme.primary,
                onPressed: () {
                  _closeOverlayEntry();
                },
                child: const Icon(
                    size: 32, color: Colors.white, Icons.zoom_out_map)),
          );
        });
    Overlay.of(context)!.insert(overlayEntry!);
    chatMessageController.index = 0;
  }

  _open(
      {MediaStream? stream,
      bool videoMedia = false,
      bool audioMedia = false,
      bool displayMedia = false}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null &&
        advancedPeerConnection.status == PeerConnectionStatus.connected) {
      await localMediaController.createVideoRender(
          stream: stream,
          videoMedia: videoMedia,
          audioMedia: audioMedia,
          displayMedia: displayMedia);
      if (audioMedia) {
        await _send(subMessageType: ChatSubMessageType.audioChat);
      } else {
        await _send();
      }
      setState(() {});
    }
  }

  ///发送视频通话消息
  Future<ChatMessage> _send(
      {ChatSubMessageType subMessageType =
          ChatSubMessageType.videoChat}) async {
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(peerId,
        contentType: ContentType.chat, subMessageType: subMessageType);
    //修改消息控制器
    chatMessageController.insert(0, chatMessage);
    await chatMessageService.send(chatMessage);

    return chatMessage;
  }

  _close() {
    localMediaController.close();
    chatMessageController.index = 0;
    setState(() {});
  }

  Widget _buildVideoViewCard(BuildContext context) {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null &&
        advancedPeerConnection.status == PeerConnectionStatus.connected) {
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

  Future<void> _onAction(int index, String name) async {
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
      child: ActionCard(
        actions: actionTileData,
        height: height,
        onPressed: _onAction,
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
            const ImageWidget(image: ''),
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
    localMediaController.removeListener(_receive);
    super.dispose();
  }
}
