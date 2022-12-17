import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/full_screen_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/video_chat_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 聊天界面，包括文本聊天，视频通话呼叫，视频通话，全屏展示四个组件
/// 支持群聊
class ChatMessageView extends StatefulWidget with TileDataMixin {
  final FullScreenWidget fullScreenWidget = const FullScreenWidget();

  ChatMessageView({
    Key? key,
  }) : super(key: key) {
    indexWidgetProvider.define(fullScreenWidget);
  }

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

  Widget _buildVideoChatWidget(BuildContext context) {
    return const VideoChatWidget();
  }

  @override
  Widget build(BuildContext context) {
    PeerConnectionStatus? status;
    if (partyType == PartyType.linkman.name) {
      status = PeerConnectionStatus.none;
      if (peerId != null) {
        var peerConnections = peerConnectionPool.get(peerId!);
        if (peerConnections.isNotEmpty) {
          //发现一个状态为connected的就设置为connected
          for (var peerConnection in peerConnections) {
            status = peerConnection.status;
            if (status == PeerConnectionStatus.connected) {
              break;
            }
          }
        }
      }
    }

    var children = [
      _buildChatMessageWidget(context),
      _buildVideoChatWidget(context),
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
