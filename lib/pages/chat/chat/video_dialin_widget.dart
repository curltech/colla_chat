import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../service/chat/chat.dart';
import 'controller/peer_connections_controller.dart';

///视频通话拨入的对话框
class VideoDialInWidget extends StatelessWidget {
  ///视频通话的消息请求
  final ChatMessage chatMessage;

  const VideoDialInWidget({Key? key, required this.chatMessage})
      : super(key: key);

  _sendReceipt(ChatReceiptType receiptType) async {
    ChatMessage? chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    if (chatReceipt != null) {
      await chatMessageService.send(chatReceipt);
      if (receiptType == ChatReceiptType.agree) {
        var peerId = chatReceipt.receiverPeerId!;
        var clientId = chatReceipt.receiverClientId!;
        await localMediaController.displayRender.createDisplayMedia();
        await localMediaController.displayRender.bindRTCVideoRender();
        await peerConnectionPool
            .create(peerId, clientId: clientId, localRenders: [
          localMediaController.displayRender,
        ]);
        peerConnectionsController.clear();
        peerConnectionsController.add(peerId, clientId: clientId);
        indexWidgetProvider.push('video_chat');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 180,
        height: 80,
        child: Column(children: [
          Row(
            children: [
              const ImageWidget(image: ''),
              Column(children: const [Text('胡劲松'), Text('邀请你进行视频通话')])
            ],
          ),
          Row(children: [
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.cameraswitch),
                color: Colors.grey),
            const Text('切换语音通话'),
            IconButton(
                onPressed: () {
                  _sendReceipt(ChatReceiptType.reject);
                  Navigator.pop(context, ChatReceiptType.reject);
                },
                icon: const Icon(Icons.clear),
                color: Colors.red),
            IconButton(
                onPressed: () {
                  _sendReceipt(ChatReceiptType.agree);
                  Navigator.pop(context, ChatReceiptType.agree);
                },
                icon: const Icon(Icons.video_call),
                color: Colors.green)
          ])
        ]));
  }
}
