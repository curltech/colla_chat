import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../service/chat/chat.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import '../../../widgets/common/simple_widget.dart';
import 'chat_message_widget.dart';
import 'controller/peer_connections_controller.dart';

///视频通话拨入的对话框
class VideoDialInWidget extends StatelessWidget {
  ///视频通话的消息请求
  final ChatMessage chatMessage;

  final Function(ChatMessage chatMessage, ChatReceiptType chatReceiptType)?
      onTap;

  const VideoDialInWidget({Key? key, required this.chatMessage, this.onTap})
      : super(key: key);

  _sendReceipt(ChatReceiptType receiptType) async {
    ChatMessage? chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    if (chatReceipt != null) {
      await chatMessageService.send(chatReceipt);
      videoChatReceiptController.chatReceipt = chatReceipt;
      String? subMessageType = chatMessage.subMessageType;
      logger.i('sent videoChat chatReceipt ${receiptType.name}');
      if (receiptType == ChatReceiptType.agree) {
        var peerId = chatReceipt.receiverPeerId!;
        var clientId = chatReceipt.receiverClientId!;
        PeerVideoRender? render;
        if (subMessageType == ChatSubMessageType.audioChat.name) {
          render =
              await localMediaController.createVideoRender(audioMedia: true);
        }
        render = render ??
            await localMediaController.createVideoRender(videoMedia: true);

        AdvancedPeerConnection? advancedPeerConnection =
            peerConnectionPool.getOne(
          peerId,
          clientId: clientId,
        );
        if (advancedPeerConnection != null) {
          await advancedPeerConnection.addRender(render);
          peerConnectionsController.add(peerId, clientId: clientId);
          indexWidgetProvider.push('video_chat');
          chatMessageController.index = 2;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(15.0),
        width: 180,
        height: 80,
        child: Column(children: [
          Row(children: [
            const ImageWidget(image: ''),
            Column(children: const [
              Text(
                '胡劲松',
                style: TextStyle(fontSize: 16),
              ),
              Text('邀请你进行视频通话', style: TextStyle(fontSize: 12)),
            ]),
            Expanded(child: Container()),
            WidgetUtil.buildCircleButton(
                onPressed: () {
                  _sendReceipt(ChatReceiptType.reject);
                  if (onTap != null) {
                    onTap!(chatMessage, ChatReceiptType.reject);
                  }
                },
                child:
                    const Icon(color: Colors.white, size: 16, Icons.call_end),
                backgroundColor: Colors.red),
            WidgetUtil.buildCircleButton(
                onPressed: () {
                  _sendReceipt(ChatReceiptType.agree);
                  if (onTap != null) {
                    onTap!(chatMessage, ChatReceiptType.agree);
                  }
                },
                child:
                    const Icon(color: Colors.white, size: 16, Icons.video_call),
                backgroundColor: Colors.green)
          ])
        ]));
  }
}
