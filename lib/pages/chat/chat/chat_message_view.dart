import 'package:colla_chat/pages/chat/chat/video_chat_widget.dart';
import 'package:colla_chat/pages/chat/chat/video_dialout_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../l10n/localization.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'chat_message_widget.dart';

/// 聊天界面，包括文本聊天，视频通话呼叫，视频通话三个组件
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
  late final String peerId;
  late final String name;
  late final String? clientId;

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_update);
    init();
  }

  init() {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
      clientId = chatSummary.clientId;
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

  @override
  Widget build(BuildContext context) {
    PeerConnectionStatus status = PeerConnectionStatus.none;
    var peerConnection = peerConnectionPool.getOne(peerId);
    if (peerConnection != null) {
      status = peerConnection.status;
    }

    var children = [
      _buildChatMessageWidget(context),
      _buildDialOutWidget(context),
      _buildVideoChatWidget(context),
    ];
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(name) +
            '(' +
            AppLocalizations.t(status.name) +
            ')'),
        withLeading: widget.withLeading,
        child: IndexedStack(
            index: chatMessageController.index, children: children));

    return appBarView;
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    chatMessageController.index = 0;
    super.dispose();
  }
}
