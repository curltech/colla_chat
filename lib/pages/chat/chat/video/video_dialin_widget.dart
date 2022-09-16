import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';


///视频通话拨入的对话框
class VideoDialInWidget extends StatelessWidget {
  ///视频通话的消息请求
  final ChatMessage chatMessage;

  final bool displayMedia;

  final bool videoMedia;

  final Function(ChatMessage chatMessage, MessageStatus chatReceiptType)? onTap;

  const VideoDialInWidget(
      {Key? key,
      this.displayMedia = true,
      this.videoMedia = false,
      required this.chatMessage,
      this.onTap})
      : super(key: key);

  _sendReceipt(MessageStatus receiptType) async {
    ChatMessage? chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    if (chatReceipt != null) {
      logger.w('sent videoChat chatReceipt ${receiptType.name}');
      await chatMessageService.send(chatReceipt);
      videoChatReceiptController.setChatReceipt(chatReceipt, ChatDirect.send);
      String? subMessageType = chatMessage.subMessageType;
      if (receiptType == MessageStatus.accepted) {
        var peerId = chatReceipt.receiverPeerId!;
        var clientId = chatReceipt.receiverClientId!;
        List<PeerVideoRender> renders = [];
        //根据title来判断是请求音频还是视频
        String? title = chatMessage.title;
        if (title == ContentType.audio.name) {
          var render =
              await localMediaController.createVideoRender(audioMedia: true);
          renders.add(render);
        } else {
          if (videoMedia) {
            var render =
                await localMediaController.createVideoRender(videoMedia: true);
            renders.add(render);
          }
          if (displayMedia) {
            var render = await localMediaController.createVideoRender(
                displayMedia: true);
            renders.add(render);
          }
        }

        AdvancedPeerConnection? advancedPeerConnection =
            peerConnectionPool.getOne(
          peerId,
          clientId: clientId,
        );
        if (advancedPeerConnection != null) {
          ChatSummary? chatSummary =
              await chatSummaryService.findCachedOneByPeerId(peerId);
          if (chatSummary != null) {
            chatMessageController.chatSummary = chatSummary;
          }
          if (renders.isNotEmpty) {
            for (var render in renders) {
              await advancedPeerConnection.addRender(render);
            }
          }
          peerConnectionsController.addPeerConnection(peerId,
              clientId: clientId);
          indexWidgetProvider.push('chat_message');
          chatMessageController.index = 2;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var name = chatMessage.senderName;
    name = name ?? '';
    return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.black.withOpacity(0.5),
        child: ListTile(
            leading: const ImageWidget(image: ''),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(AppLocalizations.t('Inviting you video chat'),
                style: const TextStyle(color: Colors.white)),
            trailing: SizedBox(
              width: 120,
              child: Row(children: [
                WidgetUtil.buildCircleButton(
                    onPressed: () {
                      _sendReceipt(MessageStatus.rejected);
                      if (onTap != null) {
                        onTap!(chatMessage, MessageStatus.rejected);
                      }
                    },
                    child: const Icon(
                        color: Colors.white, size: 16, Icons.call_end),
                    backgroundColor: Colors.red),
                WidgetUtil.buildCircleButton(
                    onPressed: () {
                      _sendReceipt(MessageStatus.accepted);
                      if (onTap != null) {
                        onTap!(chatMessage, MessageStatus.accepted);
                      }
                    },
                    child: const Icon(
                        color: Colors.white, size: 16, Icons.video_call),
                    backgroundColor: Colors.green)
              ]),
            )));
  }
}
