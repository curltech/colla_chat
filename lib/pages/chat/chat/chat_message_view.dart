import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_input.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/full_screen_chat_message_widget.dart';
import 'package:colla_chat/pages/chat/chat/sfu_video_chat_widget.dart';
import 'package:colla_chat/pages/chat/chat/video_chat_widget.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_edit_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/websocket/universal_websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webrtc_interface/webrtc_interface.dart';
import 'package:window_manager/window_manager.dart';

/// 聊天界面，包括文本聊天，视频通话呼叫，视频通话，全屏展示四个组件
/// 支持群聊
class ChatMessageView extends StatefulWidget with TileDataMixin {
  final FullScreenChatMessageWidget fullScreenChatMessageWidget =
      FullScreenChatMessageWidget();
  final VideoChatWidget videoChatWidget = VideoChatWidget();
  final SfuVideoChatWidget sfuVideoChatWidget = SfuVideoChatWidget();
  final ChatMessageWidget chatMessageWidget = ChatMessageWidget();
  final ChatMessageInputWidget chatMessageInputWidget =
      ChatMessageInputWidget();

  ChatMessageView({
    super.key,
  }) {
    indexWidgetProvider.define(fullScreenChatMessageWidget);
    indexWidgetProvider.define(videoChatWidget);
    indexWidgetProvider.define(sfuVideoChatWidget);
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
  final Rx<RTCPeerConnectionState?> _peerConnectionState =
      Rx<RTCPeerConnectionState?>(null);
  final Rx<RTCDataChannelState?> _dataChannelState =
      Rx<RTCDataChannelState?>(null);
  final Rx<bool?> _initiator = Rx<bool?>(null);
  StreamSubscription<WebrtcEvent>? connectionStateStreamSubscription;
  StreamSubscription<WebrtcEvent>? dataChannelStateStreamSubscription;
  StreamSubscription<WebrtcEvent>? signalingStateStreamSubscription;
  StreamSubscription<WebrtcEvent>? closedStreamSubscription;
  StreamSubscription<WebrtcEvent>? initiatorStreamSubscription;

  double visibleFraction = 0.0;
  NoScreenshot? noScreenshot;
  ScreenshotCallback? screenshotCallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    chatMessageController.getChatSummary().addListener(_updateChatSummary);
    WakelockPlus.enable();

    ///不准截屏
    if (platformParams.mobile) {
      try {
        noScreenshot = NoScreenshot.instance;
        screenshotCallback = ScreenshotCallback();
        noScreenshot!.screenshotOff();
        screenshotCallback!.addListener(() {
          logger.w('screenshot');
        });
      } catch (e) {
        logger.e('screenshotOff failure:$e');
      }
    }

    ///初始化数据
    _updateChatSummary();
  }

  /// 消息窗口恢复的时候，恢复webrtc的连接
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      logger.i('chat message window switch to foreground');
      _createPeerConnection();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      logger.i('app switch new state:$state');
    }
  }

  @override
  void onWindowFocus() {
    //logger.i('chat message window switch to foreground');
    _createPeerConnection();
  }

  @override
  void onWindowEvent(String eventName) {
    //logger.i('[WindowManager] chat message view onWindowEvent: $eventName');
  }

  _updateChatSummary() {
    ///初始化数据
    _createPeerConnection();
    _buildReadStatus();
  }

  ///更新为已读状态
  Future<void> _buildReadStatus() async {
    var chatSummary = chatMessageController.chatSummary;
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
  ///在初始化，窗口恢复，背景恢复都会调用，因此需要能够重复调用
  ///如果ChatGPT，则设置
  _createPeerConnection() async {
    await websocketPool.connect();
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    String partyType = chatSummary.partyType!;
    if (partyType == PartyType.linkman.name) {
      await _createLinkmanPeerConnection(peerId);
    } else if (partyType == PartyType.group.name) {
      await _createGroupPeerConnection(peerId);
    } else if (partyType == PartyType.conference.name) {
      await _createGroupPeerConnection(peerId);
    }
  }

  _createDataChannel() async {
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    List<AdvancedPeerConnection> advancedPeerConnections =
        await peerConnectionPool.get(peerId);
    AdvancedPeerConnection? advancedPeerConnection =
        advancedPeerConnections.firstOrNull;
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.createDataChannel();
    }
  }

  _disconnectPeerConnection() async {
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    String partyType = chatSummary.partyType!;
    if (partyType == PartyType.linkman.name) {
      await _disconnectLinkmanPeerConnection(peerId);
    }
  }

  ///创建linkman的PeerConnection，可以重复调用只会创建一次
  _createLinkmanPeerConnection(String peerId) async {
    ///未来应该可以自己连接另一个自己
    if (peerId == myself.peerId) {
      _peerConnectionState.value = null;
      _dataChannelState.value = null;
      _initiator.value = null;
      return;
    }
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman == null) {
      _peerConnectionState.value = null;
      _dataChannelState.value = null;
      _initiator.value = null;
      return;
    }
    if (linkman.linkmanStatus != LinkmanStatus.G.name) {
      AdvancedPeerConnection? advancedPeerConnection;
      List<AdvancedPeerConnection> advancedPeerConnections =
          await peerConnectionPool.get(peerId);
      //如果连接不存在，则创建新连接，
      if (advancedPeerConnections.isEmpty) {
        advancedPeerConnection = await peerConnectionPool.createOffer(peerId);
        if (advancedPeerConnection != null) {
          _peerConnectionState.value = advancedPeerConnection.connectionState;
          _dataChannelState.value = advancedPeerConnection.dataChannelState;
          _initiator.value =
              advancedPeerConnection.basePeerConnection.initiator;
        } else {
          _peerConnectionState.value = null;
          _dataChannelState.value = null;
        }
      } else {
        advancedPeerConnection = advancedPeerConnections.first;
        for (AdvancedPeerConnection advancedPeerConnection
            in advancedPeerConnections) {
          _peerConnectionState.value = advancedPeerConnection.connectionState;
          _dataChannelState.value = advancedPeerConnection.dataChannelState;
          _initiator.value =
              advancedPeerConnection.basePeerConnection.initiator;
          if (advancedPeerConnection.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            break;
          }
        }
      }
      connectionStateStreamSubscription = advancedPeerConnection?.listen(
          WebrtcEventType.connectionState, _updatePeerConnectionState);
      dataChannelStateStreamSubscription = advancedPeerConnection?.listen(
          WebrtcEventType.dataChannelState, _updatePeerConnectionState);
      signalingStateStreamSubscription = advancedPeerConnection?.listen(
          WebrtcEventType.signalingState, _updatePeerConnectionState);
      closedStreamSubscription = advancedPeerConnection?.listen(
          WebrtcEventType.closed, _updatePeerConnectionState);
      initiatorStreamSubscription = advancedPeerConnection?.listen(
          WebrtcEventType.initiator, _updatePeerConnectionState);
    }
  }

  _disconnectLinkmanPeerConnection(String peerId) async {
    if (peerId == myself.peerId) {
      return;
    }
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman == null) {
      return;
    }
    if (linkman.linkmanStatus != LinkmanStatus.G.name) {
      List<AdvancedPeerConnection> advancedPeerConnections =
          await peerConnectionPool.get(peerId);
      //如果连接存在，则关闭连接
      if (advancedPeerConnections.isNotEmpty) {
        for (AdvancedPeerConnection advancedPeerConnection
            in advancedPeerConnections) {
          await advancedPeerConnection.close();
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
            await peerConnectionPool.get(memberPeerId);
        if (advancedPeerConnections.isEmpty) {
          AdvancedPeerConnection? advancedPeerConnection =
              await peerConnectionPool.createOffer(memberPeerId);
          if (advancedPeerConnection != null) {
            _peerConnectionState.value = advancedPeerConnection.connectionState;
            _dataChannelState.value = advancedPeerConnection.dataChannelState;
            _initiator.value =
                advancedPeerConnection.basePeerConnection.initiator;
          } else {
            _peerConnectionState.value = null;
            _dataChannelState.value = null;
          }
        } else {
          for (AdvancedPeerConnection advancedPeerConnection
              in advancedPeerConnections) {
            _peerConnectionState.value = advancedPeerConnection.connectionState;
            _dataChannelState.value = advancedPeerConnection.dataChannelState;
            _initiator.value =
                advancedPeerConnection.basePeerConnection.initiator;
            if (advancedPeerConnection.connectionState ==
                RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
              break;
            }
          }
        }
      }
    }
  }

  Future<void> _updatePeerConnectionState(WebrtcEvent event) async {
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    if (peerId != event.peerId) {
      logger.w('peerId is not same');
      return;
    }
    WebrtcEventType eventType = event.eventType;
    if (eventType == WebrtcEventType.signalingState) {
      RTCSignalingState? state = event.data;
      // if (mounted) {
      //   DialogUtil.info(
      //       content: AppLocalizations.t(
      //               'PeerConnection signalingState was changed to ') +
      //           AppLocalizations.t(state.toString().substring(21)));
      // }
    } else if (eventType == WebrtcEventType.closed) {
      _peerConnectionState.value =
          RTCPeerConnectionState.RTCPeerConnectionStateClosed;
      _dataChannelState.value = RTCDataChannelState.RTCDataChannelClosed;
      _initiator.value = null;
      // if (mounted) {
      //   DialogUtil.info(
      //       content: AppLocalizations.t('PeerConnection was closed'));
      // }
    } else if (eventType == WebrtcEventType.connectionState) {
      RTCPeerConnectionState? state = event.data;
      RTCPeerConnectionState? oldState = _peerConnectionState.value;
      if (oldState != state) {
        _peerConnectionState.value = state;
        if (_peerConnectionState.value !=
            RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          // if (mounted) {
          //   String stateText = "Unknown";
          //   if (state != null) {
          //     stateText = state.name.substring(22);
          //   }
          //   DialogUtil.info(
          //       content:
          //           AppLocalizations.t('PeerConnection state was changed to ') +
          //               AppLocalizations.t(stateText));
          // }
        } else {
          // if (mounted) {
          //   DialogUtil.info(
          //       content: AppLocalizations.t('PeerConnection was closed'));
          // }
        }
      }
    } else if (eventType == WebrtcEventType.dataChannelState) {
      RTCDataChannelState? state = event.data;
      _dataChannelState.value = state;
      // if (mounted) {
      //   DialogUtil.info(
      //       content:
      //           AppLocalizations.t('PeerConnection initiator was changed to ') +
      //               _initiator.value.toString());
      // }
    } else if (eventType == WebrtcEventType.initiator) {
      _initiator.value = event.data;
      // if (mounted) {
      //   DialogUtil.info(
      //       content:
      //           AppLocalizations.t('PeerConnection initiator was changed to ') +
      //               _initiator.value.toString());
      // }
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
    final Widget chatMessageView = Obx(() {
      var height = chatMessageViewController.chatMessageHeight;
      Widget chatMessageWidget =
          SizedBox(height: height, child: widget.chatMessageWidget);
      return VisibilityDetector(
          key: UniqueKey(),
          onVisibilityChanged: (VisibilityInfo visibilityInfo) {
            if (visibleFraction == 0.0 && visibilityInfo.visibleFraction > 0) {
              // logger.i(
              //     'ChatMessageView visibleFraction from 0 to ${visibilityInfo.visibleFraction}');
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
      RTCPeerConnectionState? peerConnectionState = _peerConnectionState.value;
      String? stateText = peerConnectionState?.name;
      stateText = stateText?.substring(22);
      stateText ??= 'Unknown';
      Widget widget;
      if (_peerConnectionState.value ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        widget = IconButton(
          onPressed: () {
            _disconnectPeerConnection();
          },
          icon: const Icon(
            Icons.wifi,
            color: Colors.white,
          ),
          // label: stateText,
          tooltip: AppLocalizations.t('Disconnect'),
        );
      } else {
        widget = IconButton(
          onPressed: () {
            _createPeerConnection();
          },
          icon: const Icon(
            Icons.wifi_off,
            color: Colors.red,
          ),
          // label: stateText,
          tooltip: AppLocalizations.t('Reconnect'),
        );
      }
      rightWidgets.add(widget);
      rightWidgets.add(const SizedBox(
        width: 5,
      ));

      RTCDataChannelState? dataChannelState = _dataChannelState.value;
      stateText = dataChannelState?.name;
      stateText = stateText?.substring(14);
      stateText ??= 'Unknown';
      if (_dataChannelState.value == RTCDataChannelState.RTCDataChannelOpen) {
        widget = IconButton(
          onPressed: null,
          icon: const Icon(
            Icons.wb_cloudy_outlined,
            color: Colors.white,
          ),
          // label: stateText,
          tooltip: AppLocalizations.t('DataChannel'),
        );
      } else {
        widget = IconButton(
          onPressed: () {
            _createDataChannel();
          },
          icon: const Icon(
            Icons.cloud_off,
            color: Colors.red,
          ),
          // label: stateText,
          tooltip: AppLocalizations.t('DataChannel'),
        );
      }
      rightWidgets.add(widget);
      rightWidgets.add(const SizedBox(
        width: 5,
      ));
      if (myself.peerProfile.developerSwitch) {
        if (_initiator.value != null) {
          if (_initiator.value!) {
            widget = Tooltip(
                message: AppLocalizations.t('Leader'),
                child: const Icon(
                  Icons.light_mode,
                  color: Colors.yellow,
                ));
          } else {
            widget = Tooltip(
                message: AppLocalizations.t('Follower'),
                child: const Icon(
                  Icons.light_mode,
                  color: Colors.grey,
                ));
          }
        }
      }
      rightWidgets.add(widget);

      rightWidgets.add(const SizedBox(
        width: 15,
      ));
    }
    if (partyType == PartyType.group.name) {
      rightWidgets.add(IconButton(
        onPressed: () async {
          ChatSummary? chatSummary = chatMessageController.chatSummary;
          if (chatSummary != null) {
            String? partyType = chatSummary.partyType;
            String? groupId = chatSummary.peerId;
            if (partyType == PartyType.group.name && groupId != null) {
              Group? group = await groupService.findCachedOneByPeerId(groupId);
              if (group != null) {
                groupNotifier.value = group;
                indexWidgetProvider.push('group_edit');
              }
            }
          }
        },
        icon: const Icon(Icons.more_vert),
        tooltip: AppLocalizations.t('More'),
      ));
    }
    if (partyType == PartyType.conference.name) {
      rightWidgets.add(IconButton(
        onPressed: () async {
          ChatSummary? chatSummary = chatMessageController.chatSummary;
          if (chatSummary != null) {
            String? partyType = chatSummary.partyType;
            String? messageId = chatSummary.messageId;
            if (partyType == PartyType.conference.name && messageId != null) {
              Conference? conference = await conferenceService
                  .findCachedOneByConferenceId(messageId);
              if (conference != null) {
                conferenceNotifier.value = conference;
                if (conference.conferenceOwnerPeerId == myself.peerId) {
                  indexWidgetProvider.push('conference_edit');
                } else {
                  indexWidgetProvider.push('conference_show');
                }
              }
            }
          }
        },
        icon: const Icon(Icons.more_vert),
        tooltip: AppLocalizations.t('More'),
      ));
    }

    return rightWidgets;
  }

  @override
  Widget build(BuildContext context) {
    Widget appBarView = Obx(() {
      Widget chatMessageWidget = _buildChatMessageWidget(context);
      var chatSummary = chatMessageController.chatSummary;
      if (chatSummary != null) {
        String name = chatSummary.name!;
        String title = AppLocalizations.t(name);
        List<Widget> rightWidgets = _buildRightWidgets(context, chatSummary);
        return AppBarView(
            title: title,
            helpPath: widget.routeName,
            withLeading: widget.withLeading,
            rightWidgets: rightWidgets,
            child: chatMessageWidget);
      }
      return AppBarView(
          title: AppLocalizations.t('No current chatSummary'),
          helpPath: widget.routeName,
          withLeading: widget.withLeading,
          child: chatMessageWidget);
    });

    return appBarView;
  }

  @override
  void dispose() {
    chatMessageController.getChatSummary().removeListener(_updateChatSummary);
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      connectionStateStreamSubscription?.cancel();
      connectionStateStreamSubscription = null;
      signalingStateStreamSubscription?.cancel();
      signalingStateStreamSubscription = null;
      closedStreamSubscription?.cancel();
      closedStreamSubscription = null;
      initiatorStreamSubscription?.cancel();
      initiatorStreamSubscription = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    WakelockPlus.disable();
    if (platformParams.mobile) {
      screenshotCallback?.dispose();
    }
    super.dispose();
  }
}
