import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../entity/chat/chat.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';

///影响全局的消息到来
class GlobalChatMessageController with ChangeNotifier {
  ChatMessage? _chatMessage;

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  set chatMessage(ChatMessage? chatMessage) {
    _chatMessage = chatMessage;
    if (chatMessage != null) {
      String peerId = chatMessage.senderPeerId!;
      String? title = chatMessage.title;
      if (chatMessage.subMessageType == ChatSubMessageType.videoChat.name) {
        if (title == null) {
          //收到视频通话邀请，显示拨入对话框VideoDialInWidget，indexView
        } else if (chatMessage.title == ChatReceiptType.agree.name) {
          //收到视频通话邀请同意回执，发出本地流，关闭拨号窗口VideoDialOutWidget，显示视频通话窗口VideoChatWidget
          AdvancedPeerConnection? advancedPeerConnection =
              peerConnectionPool.getOne(peerId);
          advancedPeerConnection!
              .addRender(localMediaController.userRender);
          localMediaController.chatReceipt = chatMessage;
        } else if (chatMessage.title == ChatReceiptType.reject.name) {
          //收到视频通话邀请拒绝回执，关闭本地流，关闭拨号窗口VideoDialOutWidget
          localMediaController.chatReceipt = chatMessage;
        }
      } else if (chatMessage.subMessageType ==
          ChatSubMessageType.audioChat.name) {
        if (title == null) {
          //收到音频通话邀请
        } else if (chatMessage.title == ChatReceiptType.agree.name) {
          //收到音频通话邀请同意回执
        } else if (chatMessage.title == ChatReceiptType.reject.name) {
          //收到音频通话邀请拒绝回执

        }
      }
    }
    notifyListeners();
  }
}

final GlobalChatMessageController globalChatMessageController =
    GlobalChatMessageController();
