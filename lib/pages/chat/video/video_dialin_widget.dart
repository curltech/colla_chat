import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';

///视频通话拨入的对话框，展示在屏幕顶部
class VideoDialInWidget extends StatelessWidget {
  ///视频通话的消息请求
  final ChatMessage chatMessage;

  final Function(ChatMessage chatMessage, MessageStatus chatReceiptType)? onTap;

  const VideoDialInWidget({Key? key, required this.chatMessage, this.onTap})
      : super(key: key);

  ///接受或者拒绝视频通话邀请的处理
  _processVideoChat(MessageStatus receiptType) async {
    var groupPeerId = chatMessage.groupPeerId;
    var groupType = chatMessage.groupType;
    var messageId = chatMessage.messageId;
    //单个联系人视频通话邀请
    if (groupPeerId == null) {
      //创建回执消息
      ChatMessage? chatReceipt =
          await chatMessageService.buildChatReceipt(chatMessage, receiptType);
      if (chatReceipt != null) {
        //发送回执
        await chatMessageService.sendAndStore(chatReceipt);
        String? subMessageType = chatMessage.subMessageType;
        if (receiptType == MessageStatus.accepted) {
          //接受视频邀请，将当前视频邀请消息放入控制器
          await videoChatMessageController.setChatMessage(chatMessage);
          var peerId = chatReceipt.receiverPeerId!;
          var clientId = chatReceipt.receiverClientId!;
          PeerVideoRender? localRender;
          //根据title来判断是请求音频还是视频，并创建本地视频render
          String? title = chatMessage.title;
          if (title == ContentType.audio.name) {
            localRender =
                await localVideoRenderController.createAudioMediaRender();
          } else if (title == ContentType.video.name) {
            // localRender =
            //     await localVideoRenderController.createVideoMediaRender();
            //测试目的，使用屏幕
            localRender =
                await localVideoRenderController.createDisplayMediaRender();
          }

          //将本地的render加入webrtc连接
          AdvancedPeerConnection? advancedPeerConnection =
              peerConnectionPool.getOne(
            peerId,
            clientId: clientId,
          );
          if (advancedPeerConnection != null) {
            await advancedPeerConnection.addLocalRender(localRender!);
            //创建房间，将连接加入房间
            List<String> participants = [myself.peerId!, peerId];
            var conference =
                Conference(messageId!, name: '', participants: participants);
            //同意视频通话则加入到视频连接池中
            RemoteVideoRenderController videoRoomRenderController =
                videoRoomRenderPool
                    .createRemoteVideoRenderController(conference);
            videoRoomRenderController
                .addAdvancedPeerConnection(advancedPeerConnection);
            indexWidgetProvider.push('chat_message');
            indexWidgetProvider.push('video_chat');
          }
        }
      }
    } else if (groupType == PartyType.group.name) {
      //群视频通话邀请
      //除了向发送方外，还需要向房间的各接收人发送回执，
      //首先检查接收人是否已经存在给自己的回执，不存在或者存在是accepted则发送回执
      //如果存在，如果是rejected或者terminated，则不发送回执
      //创建回执消息
      List<ChatMessage> chatReceipts = await chatMessageService
          .buildGroupChatReceipt(chatMessage, receiptType);
      if (chatReceipts.isNotEmpty) {
        for (var chatReceipt in chatReceipts) {
          //发送回执
          await chatMessageService.sendAndStore(chatReceipt);
        }
      }
      Map json = JsonUtil.toJson(chatMessage.content!);
      var conference = Conference.fromJson(json);
      await conferenceService.store(conference);
      if (receiptType == MessageStatus.accepted) {}
    } else if (groupType == PartyType.conference.name) {
      //会议视频通话邀请
      //除了向发送方外，还需要向房间的各接收人发送回执，
      //首先检查接收人是否已经存在给自己的回执，不存在或者存在是accepted则发送回执
      //如果存在，如果是rejected或者terminated，则不发送回执
      if (receiptType == MessageStatus.accepted) {
        Map json = JsonUtil.toJson(chatMessage.content!);
        var conference = Conference.fromJson(json);
        await conferenceService.store(conference);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var name = chatMessage.senderName;
    name = name ?? '';
    return ListTile(
        leading: myself.avatarImage,
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(AppLocalizations.t('Inviting you video chat'),
            style: const TextStyle(color: Colors.white)),
        trailing: SizedBox(
          width: 130,
          child: Row(children: [
            WidgetUtil.buildCircleButton(
                onPressed: () {
                  _processVideoChat(MessageStatus.rejected);
                  if (onTap != null) {
                    onTap!(chatMessage, MessageStatus.rejected);
                  }
                },
                child:
                    const Icon(color: Colors.white, size: 16, Icons.call_end),
                backgroundColor: Colors.red),
            WidgetUtil.buildCircleButton(
                onPressed: () {
                  _processVideoChat(MessageStatus.accepted);
                  if (onTap != null) {
                    onTap!(chatMessage, MessageStatus.accepted);
                  }
                },
                child:
                    const Icon(color: Colors.white, size: 16, Icons.video_call),
                backgroundColor: Colors.green),
          ]),
        ));
  }
}
