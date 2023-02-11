import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_receipt_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';

///视频通话拨入的对话框，展示在屏幕顶部
class VideoDialInWidget extends StatelessWidget {
  ///视频通话的消息请求
  final ChatMessage chatMessage;

  //缺省用视频还是屏幕媒体
  final bool videoMedia;

  final Function(ChatMessage chatMessage, MessageStatus chatReceiptType)? onTap;

  const VideoDialInWidget(
      {Key? key,
      this.videoMedia = false,
      required this.chatMessage,
      this.onTap})
      : super(key: key);

  _sendReceipt(MessageStatus receiptType) async {
    ChatMessage? chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    if (chatReceipt != null) {
      logger.w('sent videoChat chatReceipt ${receiptType.name}');
      await chatMessageService.sendAndStore(chatReceipt);
      videoChatReceiptController.receivedChatReceipt(chatReceipt, ChatDirect.send);
      String? subMessageType = chatMessage.subMessageType;
      if (receiptType == MessageStatus.accepted) {
        var peerId = chatReceipt.receiverPeerId!;
        var clientId = chatReceipt.receiverClientId!;
        List<PeerVideoRender> localRenders = [];
        //根据title来判断是请求音频还是视频
        String? title = chatMessage.title;
        if (title == ContentType.audio.name) {
          var render =
              await localVideoRenderController.createAudioMediaRender();
          localRenders.add(render);
        } else {
          if (videoMedia) {
            var render =
                await localVideoRenderController.createVideoMediaRender();
            localRenders.add(render);
          } else {
            var render =
                await localVideoRenderController.createDisplayMediaRender();
            localRenders.add(render);
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
          if (localRenders.isNotEmpty) {
            for (var render in localRenders) {
              await advancedPeerConnection.addLocalRender(render);
            }
          }

          ///同意视频通话则加入到视频连接池中
          Room? room = advancedPeerConnection.room;
          if (room == null) {
            String? content = chatMessage.content;
            //无房间
            if (content == null) {
              room = Room(
                  '${advancedPeerConnection.peerId}:${advancedPeerConnection.clientId}');
            } else {
              Map map = JsonUtil.toJson(content);
              room = Room.fromJson(map);
            }
            advancedPeerConnection.room = room;
          }
          VideoRoomRenderController videoRoomController =
              videoRoomRenderPool.createRoomController(room);
          videoRoomRenderPool.roomId = room.roomId;
          videoRoomController.addAdvancedPeerConnection(advancedPeerConnection);
          indexWidgetProvider.push('chat_message');
          indexWidgetProvider.push('video_chat');
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
            leading: myself.avatarImage,
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
