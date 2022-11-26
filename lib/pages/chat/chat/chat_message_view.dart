import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/full_screen_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/video_chat_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/video_dialout_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 聊天界面，包括文本聊天，视频通话呼叫，视频通话，全屏展示四个组件
/// 支持群聊
class ChatMessageView extends StatefulWidget with TileDataMixin {
  ChatMessageView({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatMessageViewState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat_message';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => 'ChatMessage';
}

class _ChatMessageViewState extends State<ChatMessageView> {
  //linkman或者group的peerId
  String? peerId;
  String? name;
  String? partyType;

  //linkman才有值
  String? clientId;

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_update);
    peerConnectionPoolController.addListener(_update);
    _init();
  }

  _init() {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
      clientId = chatSummary.clientId;
      partyType = chatSummary.partyType;
    } else {
      logger.e('chatSummary is null');
    }
  }

  _update() {
    setState(() {});
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildChatMessageWidget(BuildContext context) {
    return ChatMessageWidget();
  }

  Widget _buildDialOutWidget(BuildContext context) {
    return const VideoDialOutWidget();
  }

  Widget _buildVideoChatWidget(BuildContext context) {
    return const VideoChatWidget();
  }

  Widget _buildFullScreenWidget(BuildContext context) {
    return const FullScreenWidget();
  }

  @override
  Widget build(BuildContext context) {
    PeerConnectionStatus? status;
    if (partyType == PartyType.linkman.name) {
      status = PeerConnectionStatus.none;
      if (peerId != null) {
        var peerConnection = peerConnectionPool.getOne(peerId!);
        if (peerConnection != null) {
          status = peerConnection.status;
        }
      }
    }

    var children = [
      _buildChatMessageWidget(context),
      _buildDialOutWidget(context),
      _buildVideoChatWidget(context),
      _buildFullScreenWidget(context),
    ];
    name = name ?? '';
    String title = AppLocalizations.t(name!);
    Widget titleWidget = Text(title);
    //     Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    //   Text(title),
    //   const SizedBox(
    //     width: 15,
    //   ),
    //   FutureBuilder(
    //     future: _getImageWidget(context),
    //     builder: (BuildContext context, AsyncSnapshot<Widget?> snapshot) {
    //       Widget widget = snapshot.data ?? Container();
    //       return widget;
    //     },
    //   ),
    // ]);
    List<Widget> rightWidgets = [];
    if (partyType == PartyType.linkman.name) {
      if (status == PeerConnectionStatus.connected) {
        rightWidgets.add(const Icon(Icons.wifi));
      } else {
        rightWidgets.add(const Icon(Icons.wifi_off));
      }
      rightWidgets.add(const SizedBox(
        width: 15,
      ));
      if (chatMessageController.chatView == ChatView.full ||
          chatMessageController.chatView == ChatView.video ||
          chatMessageController.chatView == ChatView.dial) {
        rightWidgets.add(InkWell(
            onTap: () {
              chatMessageController.chatView = ChatView.text;
            },
            child: const Icon(Icons.assignment_return)));
        rightWidgets.add(const SizedBox(
          width: 15,
        ));
      }
    }
    var appBarView = AppBarView(
        title: titleWidget,
        withLeading: widget.withLeading,
        rightWidgets: rightWidgets,
        child: IndexedStack(
            index: chatMessageController.chatView.index, children: children));

    return appBarView;
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    peerConnectionPoolController.removeListener(_update);
    super.dispose();
  }
}
