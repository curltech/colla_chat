import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_input.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/full_screen_chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/video_chat_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/openai/openai_chat_gpt.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock/wakelock.dart';
import 'package:window_manager/window_manager.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// 聊天界面，包括文本聊天，视频通话呼叫，视频通话，全屏展示四个组件
/// 支持群聊
class ChatMessageView extends StatefulWidget with TileDataMixin {
  final FullScreenChatMessageWidget fullScreenChatMessageWidget =
      const FullScreenChatMessageWidget();
  final VideoChatWidget videoChatWidget = VideoChatWidget();
  final ChatMessageWidget chatMessageWidget = ChatMessageWidget();
  final ChatMessageInputWidget chatMessageInputWidget =
      ChatMessageInputWidget();

  ChatMessageView({
    Key? key,
  }) : super(key: key) {
    indexWidgetProvider.define(fullScreenChatMessageWidget);
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

class _ChatMessageViewState extends State<ChatMessageView>
    with WidgetsBindingObserver, WindowListener {
  final ValueNotifier<PeerConnectionStatus> _peerConnectionStatus =
      ValueNotifier<PeerConnectionStatus>(PeerConnectionStatus.none);
  final ValueNotifier<ChatSummary?> _chatSummary =
      ValueNotifier<ChatSummary?>(chatMessageController.chatSummary);
  final ValueNotifier<double> chatMessageHeight = ValueNotifier<double>(0);
  double visibleFraction = 0.0;
  NoScreenshot? noScreenshot;
  ScreenshotCallback? screenshotCallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    chatMessageController.addListener(_updateChatMessage);
    chatMessageViewController.addListener(_updateChatMessageView);
    _createPeerConnection();
    _buildReadStatus();
    _updateChatMessageView();
    Wakelock.enable();
    if (platformParams.mobile) {
      noScreenshot = NoScreenshot.instance;
      screenshotCallback = ScreenshotCallback();
      noScreenshot!.screenshotOff();
      screenshotCallback!.addListener(() {
        logger.w('screenshot');
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    logger.i('app switch new state:$state');
    switch (state) {
      case AppLifecycleState.resumed:
        _createPeerConnection();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      default:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    logger.i('app change metrics');
  }

  @override
  void onWindowEvent(String eventName) {
    //logger.i('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void onWindowRestore() {
    _createPeerConnection();
  }

  _updateChatMessageView() {
    chatMessageHeight.value = chatMessageViewController.chatMessageHeight;
  }

  _updateChatMessage() {
    _chatSummary.value = chatMessageController.chatSummary;
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
  ///如果ChatGPT，则设置
  _createPeerConnection() async {
    var chatSummary = _chatSummary.value;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    chatMessageController.chatGPT = null;
    String peerId = chatSummary.peerId!;
    String partyType = chatSummary.partyType!;
    peerConnectionPool.registerWebrtcEvent(
        peerId, WebrtcEventType.status, _updatePeerConnectionStatus);
    if (partyType == PartyType.linkman.name) {
      await _createLinkmanPeerConnection(peerId);
    } else if (partyType == PartyType.group.name) {
      await _createGroupPeerConnection(peerId);
    } else if (partyType == PartyType.conference.name) {
      await _createGroupPeerConnection(peerId);
    }
  }

  ///linkman的PeerConnection初始化
  _createLinkmanPeerConnection(String peerId) async {
    if (peerId == myself.peerId) {
      return;
    }
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman == null) {
      return;
    }
    if (linkman.linkmanStatus == LinkmanStatus.chatGPT.name) {
      ChatGPT chatGPT = ChatGPT(linkman.peerId);
      if (StringUtil.isNotEmpty(linkman.peerPublicKey)) {
        chatGPT.model = linkman.peerPublicKey!;
      }
      chatMessageController.chatGPT = chatGPT;
    } else {
      List<AdvancedPeerConnection> advancedPeerConnections =
          peerConnectionPool.get(peerId);
      //如果连接不存在，则创建新连接
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
          if (advancedPeerConnection.status == PeerConnectionStatus.connected) {
            break;
          }
        }
      }
    }
  }

  ///群或者会议的成员全部尝试连接
  _createGroupPeerConnection(String peerId) async {
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

  Future<void> _updatePeerConnectionStatus(WebrtcEvent event) async {
    PeerConnectionStatus status = event.data;
    var oldStatus = _peerConnectionStatus.value;
    if (oldStatus != status) {
      _peerConnectionStatus.value = status;
      if (_peerConnectionStatus.value == PeerConnectionStatus.connected) {
        if (mounted) {
          DialogUtil.info(context,
              content:
                  '${AppLocalizations.t('PeerConnection status was changed from ')}${oldStatus.name}${AppLocalizations.t(' to ')}${status.name}');
        }
      } else {
        if (mounted) {
          // DialogUtil.error(context,
          //     content:
          //         '${AppLocalizations.t('PeerConnection status was changed from ')}${oldStatus.name}${AppLocalizations.t(' to ')}${status.name}');
        }
      }
    }
  }

  ///创建KeyboardActionsConfig钩住所有的字段
  KeyboardActionsConfig _buildKeyboardActionsConfig(BuildContext context) {
    List<KeyboardActionsItem> actions = [
      KeyboardActionsItem(
        focusNode: chatMessageViewController.focusNode,
        displayActionBar: false,
        displayArrows: false,
        displayDoneButton: false,
      )
    ];
    KeyboardActionsPlatform keyboardActionsPlatform =
        KeyboardActionsPlatform.ALL;
    if (platformParams.ios) {
      keyboardActionsPlatform = KeyboardActionsPlatform.IOS;
    } else if (platformParams.android) {
      keyboardActionsPlatform = KeyboardActionsPlatform.ANDROID;
    }
    return KeyboardActionsConfig(
      keyboardActionsPlatform: keyboardActionsPlatform,
      keyboardBarColor: myself.primary,
      nextFocus: false,
      actions: actions,
    );
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildChatMessageWidget(BuildContext context) {
    final Widget chatMessageView = ValueListenableBuilder(
        valueListenable: chatMessageHeight,
        builder: (BuildContext context, double value, Widget? child) {
          var height = chatMessageViewController.chatMessageHeight;
          Widget chatMessageWidget =
              SizedBox(height: height, child: widget.chatMessageWidget);
          return VisibilityDetector(
              key: UniqueKey(),
              onVisibilityChanged: (VisibilityInfo visibilityInfo) {
                if (visibleFraction == 0.0 &&
                    visibilityInfo.visibleFraction > 0) {
                  logger.i(
                      'ChatMessageView visibleFraction from 0 to ${visibilityInfo.visibleFraction}');
                  _createPeerConnection();
                }
                visibleFraction = visibilityInfo.visibleFraction;
              },
              child: KeyboardActions(
                  autoScroll: true,
                  config: _buildKeyboardActionsConfig(context),
                  child: Column(children: <Widget>[
                    chatMessageWidget,
                    Divider(
                      color: Colors.white.withOpacity(AppOpacity.xlOpacity),
                      height: 1.0,
                    ),
                    widget.chatMessageInputWidget
                  ])));
        });

    return chatMessageView;
  }

  List<Widget> _buildRightWidgets(
      BuildContext context, ChatSummary chatSummary) {
    String partyType = chatSummary.partyType!;
    List<Widget> rightWidgets = [];
    if (partyType == PartyType.linkman.name) {
      var peerConnectionStatusWidget = ValueListenableBuilder(
          valueListenable: _peerConnectionStatus,
          builder: (context, value, child) {
            Widget widget = const Icon(
              Icons.wifi,
              color: Colors.white,
            );
            if (_peerConnectionStatus.value != PeerConnectionStatus.connected) {
              widget = IconButton(
                  onPressed: () {
                    _createPeerConnection();
                  },
                  icon: const Icon(
                    Icons.wifi_off,
                    color: Colors.red,
                  ));
            }
            return Tooltip(
                message: AppLocalizations.t('Webrtc status'), child: widget);
          });
      rightWidgets.add(peerConnectionStatusWidget);
      rightWidgets.add(const SizedBox(
        width: 15,
      ));
    }
    if (partyType == PartyType.group.name) {
      rightWidgets.add(IconButton(
          onPressed: () async {
            indexWidgetProvider.push('linkman_edit_group');
          },
          icon: const Icon(Icons.more_vert)));
    }
    if (partyType == PartyType.conference.name) {
      rightWidgets.add(IconButton(
          onPressed: () {
            indexWidgetProvider.push('conference_add');
          },
          icon: const Icon(Icons.more_vert)));
    }

    return rightWidgets;
  }

  @override
  Widget build(BuildContext context) {
    Widget chatMessageWidget = _buildChatMessageWidget(context);
    Widget appBarView = ValueListenableBuilder(
        valueListenable: _chatSummary,
        builder:
            (BuildContext context, ChatSummary? chatSummary, Widget? child) {
          if (chatSummary != null) {
            String name = chatSummary.name!;
            String title = AppLocalizations.t(name);
            return AppBarView(
                titleWidget: CommonAutoSizeText(title),
                withLeading: widget.withLeading,
                rightWidgets: _buildRightWidgets(context, chatSummary),
                child: chatMessageWidget);
          }
          return AppBarView(
              titleWidget: CommonAutoSizeText(
                  AppLocalizations.t('No current chatSummary')),
              withLeading: widget.withLeading,
              child: chatMessageWidget);
        });

    return appBarView;
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_updateChatMessage);
    chatMessageViewController.removeListener(_updateChatMessageView);
    var chatSummary = _chatSummary.value;
    if (chatSummary != null) {
      peerConnectionPool.unregisterWebrtcEvent(chatSummary.peerId!,
          WebrtcEventType.status, _updatePeerConnectionStatus);
    }
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    Wakelock.disable();
    if (platformParams.mobile) {
      screenshotCallback?.dispose();
    }
    super.dispose();
  }
}
