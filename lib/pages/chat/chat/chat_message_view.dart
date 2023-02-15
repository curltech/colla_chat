import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_input.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/full_screen_widget.dart';
import 'package:colla_chat/pages/chat/chat/video_chat_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 聊天界面，包括文本聊天，视频通话呼叫，视频通话，全屏展示四个组件
/// 支持群聊
class ChatMessageView extends StatefulWidget with TileDataMixin {
  final FullScreenWidget fullScreenWidget = const FullScreenWidget();
  final VideoChatWidget videoChatWidget = const VideoChatWidget();
  final ChatMessageWidget chatMessageWidget = ChatMessageWidget();
  final ChatMessageInputWidget chatMessageInputWidget =
      ChatMessageInputWidget();

  ChatMessageView({
    Key? key,
  }) : super(key: key) {
    indexWidgetProvider.define(fullScreenWidget);
    indexWidgetProvider.define(videoChatWidget);
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
  IconData get iconData => Icons.chat;

  @override
  String get title => 'ChatMessage';
}

class _ChatMessageViewState extends State<ChatMessageView> {
  final ValueNotifier<PeerConnectionStatus> _peerConnectionStatus =
      ValueNotifier<PeerConnectionStatus>(PeerConnectionStatus.none);
  final ValueNotifier<ChatSummary?> _chatSummary =
      ValueNotifier<ChatSummary?>(chatMessageController.chatSummary);

  @override
  void initState() {
    super.initState();
    _createPeerConnection();
    _buildReadStatus();
  }

  ///更新为已读状态
  Future<void> _buildReadStatus() async {
    var chatSummary = _chatSummary.value;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    await chatMessageService.update(
        {'status': MessageStatus.read.name, 'readTime': DateUtil.currentDate()},
        where:
            'senderPeerId = ? and receiverPeerId = ? and readTime is null and (status=? or status=? or status=? or status=?)',
        whereArgs: [
          peerId,
          myself.peerId!,
          MessageStatus.unsent.name,
          MessageStatus.sent.name,
          MessageStatus.received.name,
          MessageStatus.send.name
        ]);
    if (chatSummary.unreadNumber > 0) {
      chatSummary.unreadNumber = 0;
      Map<String, dynamic> entity = {'unreadNumber': 0};
      await chatSummaryService
          .update(entity, where: 'peerId=?', whereArgs: [peerId]);
      if (chatSummary.partyType == PartyType.linkman.name) {
        linkmanChatSummaryController.refresh();
      }
      if (chatSummary.partyType == PartyType.group.name) {
        groupChatSummaryController.refresh();
      }
    }
  }

  ///初始化，webrtc如果没有连接，尝试连接
  _createPeerConnection() async {
    var chatSummary = _chatSummary.value;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    String partyType = chatSummary.partyType!;
    peerConnectionPool.registerWebrtcEvent(
        peerId, WebrtcEventType.status, _updatePeerConnectionStatus);
    if (partyType == PartyType.linkman.name) {
      if (peerId != myself.peerId) {
        List<AdvancedPeerConnection> advancedPeerConnections =
            peerConnectionPool.get(peerId);
        if (advancedPeerConnections.isEmpty) {
          AdvancedPeerConnection? advancedPeerConnection =
              await peerConnectionPool.create(peerId);
          if (advancedPeerConnection != null) {
            _peerConnectionStatus.value = advancedPeerConnection.status;
          } else {
            _peerConnectionStatus.value = PeerConnectionStatus.none;
          }
        } else {
          for (AdvancedPeerConnection advancedPeerConnection
              in advancedPeerConnections) {
            _peerConnectionStatus.value = advancedPeerConnection.status;
            if (advancedPeerConnection.status ==
                PeerConnectionStatus.connected) {
              break;
            }
          }
        }
      }
    } else if (partyType == PartyType.group.name) {
      List<GroupMember> groupMembers =
          await groupMemberService.findByGroupId(peerId);
      for (var groupMember in groupMembers) {
        String? memberPeerId = groupMember.memberPeerId;
        if (memberPeerId != null && memberPeerId != myself.peerId) {
          List<AdvancedPeerConnection> advancedPeerConnections =
              peerConnectionPool.get(memberPeerId);
          if (advancedPeerConnections.isEmpty) {
            peerConnectionPool.create(memberPeerId);
          }
        }
      }
    }
  }

  _updatePeerConnectionStatus(WebrtcEvent event) {
    PeerConnectionStatus status = event.data;
    var oldStatus = _peerConnectionStatus.value;
    if (oldStatus != status) {
      _peerConnectionStatus.value = status;
      if (_peerConnectionStatus.value == PeerConnectionStatus.connected) {
        DialogUtil.info(context,
            content: AppLocalizations.t(
                'PeerConnection status was changed from ${oldStatus.name} to ${status.name}'));
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t(
                'PeerConnection status was changed from ${oldStatus.name} to ${status.name}'));
      }
    }
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildChatMessageWidget(BuildContext context) {
    return Column(children: <Widget>[
      Flexible(
        //使用列表渲染消息
        child: widget.chatMessageWidget,
      ),
      const Divider(
        height: 1.0,
      ),
      widget.chatMessageInputWidget,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var chatSummary = _chatSummary.value;
    if (chatSummary == null) {
      return AppBarView(
          title: AppLocalizations.t('No current PeerId'),
          withLeading: widget.withLeading,
          child: Container());
    }
    String peerId = chatSummary.peerId!;
    String name = chatSummary.name!;
    String partyType = chatSummary.partyType!;
    String title = AppLocalizations.t(name);
    Widget titleWidget = Text(title);
    List<Widget> rightWidgets = [];
    if (partyType == PartyType.linkman.name) {
      var peerConnectionStatusWidget = ValueListenableBuilder(
          valueListenable: _peerConnectionStatus,
          builder: (context, value, child) {
            Widget widget = const Icon(Icons.wifi);
            if (peerId == myself.peerId) {
              widget = myself.avatarImage ?? AppImage.mdAppImage;
            } else if (_peerConnectionStatus.value !=
                PeerConnectionStatus.connected) {
              widget = InkWell(
                  onTap: () {
                    _createPeerConnection();
                  },
                  child: const Icon(Icons.wifi_off));
            }
            return widget;
          });
      rightWidgets.add(peerConnectionStatusWidget);
      rightWidgets.add(const SizedBox(
        width: 15,
      ));
    }

    var appBarView = KeepAliveWrapper(
        child: AppBarView(
            titleWidget: titleWidget,
            withLeading: widget.withLeading,
            rightWidgets: rightWidgets,
            child: _buildChatMessageWidget(context)));

    return appBarView;
  }

  @override
  void dispose() {
    var chatSummary = _chatSummary.value;
    if (chatSummary != null) {
      peerConnectionPool.unregisterWebrtcEvent(chatSummary.peerId!,
          WebrtcEventType.status, _updatePeerConnectionStatus);
    }
    super.dispose();
  }
}
