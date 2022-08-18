import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../service/chat/chat.dart';
import '../../../tool/util.dart';

///视频通话拨入的对话框
class VideoDialInWidget extends StatelessWidget {
  ///视频通话的消息请求
  final ChatMessage chatMessage;

  const VideoDialInWidget({Key? key, required this.chatMessage})
      : super(key: key);

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
                onPressed: () async {
                  ChatMessage? chatReceipt = await chatMessageService
                      .buildChatReceipt(chatMessage, ChatReceiptType.reject);
                  if (chatReceipt != null) {
                    String json = JsonUtil.toJsonString(chatMessage);
                    List<int> data = CryptoUtil.stringToUtf8(json);
                    peerConnectionPool.send(chatReceipt.receiverPeerId!, data);
                  }
                },
                icon: const Icon(Icons.clear),
                color: Colors.red),
            IconButton(
                onPressed: () async {
                  ChatMessage? chatReceipt = await chatMessageService
                      .buildChatReceipt(chatMessage, ChatReceiptType.agree);
                  if (chatReceipt != null) {
                    String json = JsonUtil.toJsonString(chatMessage);
                    List<int> data = CryptoUtil.stringToUtf8(json);
                    peerConnectionPool.send(chatReceipt.receiverPeerId!, data);
                  }
                },
                icon: const Icon(Icons.video_call),
                color: Colors.green)
          ])
        ]));
  }
}
