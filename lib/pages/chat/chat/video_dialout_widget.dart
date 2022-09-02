import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../service/chat/chat.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/base_peer_connection.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import '../../../widgets/common/image_widget.dart';
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

///视频通话拨出的窗口
class VideoDialOutWidget extends StatefulWidget {
  const VideoDialOutWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoDialOutWidgetState();
  }
}

class _VideoDialOutWidgetState extends State<VideoDialOutWidget> {
  late final String peerId;
  String? name;
  String? clientId;
  bool isOpen = false;
  PeerVideoRender? render;

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

  _receive() {
    ChatMessage? chatReceipt = localMediaController.chatReceipt;
    if (chatReceipt != null) {
      String? title = chatReceipt.title;
      String? subMessageType = chatReceipt.subMessageType;
      if (subMessageType != null) {
        logger.i('received videoChat chatReceipt $title');
        if (subMessageType == ChatSubMessageType.chatReceipt.name) {
          if (title == ChatReceiptType.agree.name) {
            var peerId = chatReceipt.senderPeerId!;
            var clientId = chatReceipt.senderClientId!;
            peerConnectionsController.clear();
            peerConnectionsController.add(peerId, clientId: clientId);
            chatMessageController.index = 2;
          } else if (title == ChatReceiptType.reject.name) {
            if (render != null) {
              localMediaController.hangup(id: render!.id);
            }
            chatMessageController.index = 0;
          }
        }
      }
    }
  }

  _open(
      {MediaStream? stream,
      bool videoMedia = false,
      bool audioMedia = false,
      bool displayMedia = false}) async {
    if (isOpen) {
      setState(() {});
      return;
    }
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null &&
        advancedPeerConnection.status == PeerConnectionStatus.connected) {
      render = await localMediaController.createVideoRender(
          stream: stream,
          videoMedia: videoMedia,
          audioMedia: audioMedia,
          displayMedia: displayMedia);
      if (audioMedia) {
        await _send(subMessageType: ChatSubMessageType.audioChat);
      } else {
        await _send();
      }
      isOpen = true;
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
    localMediaController.chatMessage = chatMessage;
    await chatMessageService.send(chatMessage);

    return chatMessage;
  }

  _close() {
    localMediaController.hangup(id: render!.id);
    isOpen = false;
    setState(() {});
  }

  Future<Widget> _buildVideoView() async {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null &&
        advancedPeerConnection.status == PeerConnectionStatus.connected) {
      Widget? videoView = render!.createVideoView(mirror: true);
      return videoView;
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FutureBuilder(
        future: _buildVideoView(),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return Center(child: Text(AppLocalizations.t('No video data')));
          }
        },
      ),
      Column(children: [
        Row(
          children: [
            const ImageWidget(image: ''),
            Column(children: [
              Text(name ?? ''),
              Text(AppLocalizations.t('Invite you video chat...'))
            ])
          ],
        ),
        const Expanded(child: Center()),
        Row(children: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.cameraswitch),
              color: Colors.grey),
          Text(AppLocalizations.t('Switch to audio chat')),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.clear),
              color: Colors.red),
          IconButton(
              onPressed: () {
                _open();
              },
              icon: const Icon(Icons.video_call),
              color: Colors.green)
        ]),
        IconButton(
            onPressed: () {
              _close();
            },
            icon: const Icon(Icons.call_end),
            color: Colors.red),
      ])
    ]);
  }

  @override
  void dispose() {
    localMediaController.removeListener(_receive);
    super.dispose();
  }
}
