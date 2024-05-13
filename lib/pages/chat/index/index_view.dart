import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/adaptive_layout_index.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message.dart';
import 'package:colla_chat/pages/chat/index/global_webrtc_event.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/notification_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class IndexView extends StatefulWidget {
  final String title;
  final AdaptiveLayoutIndex adaptiveLayoutIndex = AdaptiveLayoutIndex();

  IndexView({super.key, required this.title});

  @override
  State<StatefulWidget> createState() {
    return _IndexViewState();
  }
}

class _IndexViewState extends State<IndexView>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        WindowListener {
  final ValueNotifier<bool> conferenceChatMessageVisible =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> chatMessageVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> conferenceJoined = ValueNotifier<bool>(false);
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();
  ChatMessage? chatMessage;

  ConferenceChatMessageController conferenceChatMessageController =
      ConferenceChatMessageController();

  //JustAudioPlayer audioPlayer = JustAudioPlayer();
  Widget bannerAvatarImage = AppImage.mdAppImage;

  StreamSubscription? _intentDataStreamSubscription;
  StreamSubscription<ChatMessage>? chatMessageStreamSubscription;
  StreamSubscription<WebrtcEvent>? errorWebrtcEventStreamSubscription;
  List<SharedFile>? _sharedFiles;

  Socket? _socket;
  StreamSubscription? _socketStreamSub;

  late final AppLifecycleListener _appLifecycleListener;
  late AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    _initShare();
    chatMessageStreamSubscription = globalChatMessage
        .chatMessageStreamController.stream
        .listen((ChatMessage chatMessage) {
      _updateGlobalChatMessage(chatMessage);
    });
    myself.addListener(_update);
    appDataProvider.addListener(_update);
    globalWebrtcEvent.onWebrtcSignal = _onWebrtcSignal;
    errorWebrtcEventStreamSubscription = globalWebrtcEvent
        .errorWebrtcEventStreamController.stream
        .listen((WebrtcEvent event) {
      _onWebrtcErrorSignal(event);
    });
    p2pConferenceClientPool.addListener(_updateConferenceJoined);
    liveKitConferenceClientPool.addListener(_updateConferenceJoined);

    _initSystemTray();
    _initObserver();
  }

  _initObserver() {
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    _appLifecycleState = SchedulerBinding.instance.lifecycleState;
    _appLifecycleListener = AppLifecycleListener(
      onShow: () {
        logger.i('app switch to show');
      },
      onResume: () {
        logger.i('app switch to resume');
      },
      onHide: () {
        logger.i('app switch to hide');
      },
      onInactive: () {
        logger.i('app switch to inactive');
      },
      onPause: () {
        logger.i('app switch to pause');
      },
      onDetach: () {
        logger.i('app switch to detach');
      },
      onRestart: () {
        logger.i('app switch to restart');
      },
      onExitRequested: () {
        logger.i('app switch to exit');
        return Future.value(AppExitResponse.exit);
      },
      onStateChange: (AppLifecycleState state) {
        logger.i('app state change:$state');
      },
    );
  }

  /// 应用窗口恢复的时候，恢复websocket的连接
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      logger.i('app switch to foreground');
      await websocketPool.connect();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      logger.i('app switch new state:$state');
    }
  }

  @override
  Future<void> onWindowFocus() async {
    //logger.i('app window focus');
    await websocketPool.connect();
  }

  ///当前系统改变了一些访问性活动的回调
  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    logger.i("didChangeAccessibilityFeatures");
  }

  ///低内存回调
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    logger.i("didHaveMemoryPressure");
  }

  ///用户本地设置变化时调用，如系统语言改变
  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    logger.i("didChangeLocales");
  }

  ///应用尺寸改变时回调，例如旋转
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    Size size =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    logger.i("didChangeMetrics  ：宽：${size.width} 高：${size.height}");
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    logger.i("didChangePlatformBrightness");
  }

  ///文字系数变化
  @override
  void didChangeTextScaleFactor() {
    super.didChangeTextScaleFactor();
    logger.i(
        "didChangeTextScaleFactor  ：${WidgetsBinding.instance.platformDispatcher.textScaleFactor}");
  }

  @override
  void onWindowEvent(String eventName) {
    //logger.i('[WindowManager] index view onWindowEvent: $eventName');
  }

  Future<bool?> _onWebrtcSignal(WebrtcEvent webrtcEvent) async {
    String name = webrtcEvent.name;
    return await DialogUtil.confirm(context,
        content: name +
            AppLocalizations.t(
                ' is a stranger, want to chat with you, are you agree?'));
  }

  Future<void> _onWebrtcErrorSignal(WebrtcEvent webrtcEvent) async {
    String name = webrtcEvent.name;
    WebrtcEventType eventType = webrtcEvent.eventType;
    if (eventType == WebrtcEventType.signal) {
      WebrtcSignal signal = webrtcEvent.data;
      if (signal.signalType == SignalType.error.name) {
        DialogUtil.error(context,
            content: name +
                AppLocalizations.t(' response error:') +
                (signal.error ?? ''));
      }
    }
  }

  Future<void> _initSystemTray() async {
    if (!platformParams.desktop) {
      return;
    }
    String path = platformParams.windows
        ? 'assets/icons/favicon-32x32.ico'
        : 'assets/images/colla-white.png';

    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    // We first init the systray menu
    await systemTray.initSystemTray(
      toolTip: AppLocalizations.t("CollaChat"),
      iconPath: path,
    );
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
          label: AppLocalizations.t('Show'),
          onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(
          label: AppLocalizations.t('Hide'),
          onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(
          label: AppLocalizations.t('Exit'),
          onClicked: (menuItem) => appWindow.close()),
    ]);
    await systemTray.setContextMenu(menu);
    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        platformParams.windows
            ? appWindow.show()
            : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        platformParams.windows
            ? systemTray.popUpContextMenu()
            : systemTray.popUpContextMenu();
      }
    });
  }

  ///初始化应用数据接受分享的监听器
  _initShare() {
    if (!platformParams.mobile) {
      return;
    }
    // 应用打开时分享的媒体文件
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedFile> value) {
      _sharedFiles = value;
      if (_sharedFiles != null && _sharedFiles!.isNotEmpty) {
        _shareChatMessage(_sharedFiles!.first);
      }
    }, onError: (err) {
      logger.e("getIntentDataStream error: $err");
    });

    // 应用关闭时分享的媒体文件
    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((List<SharedFile> value) {
      _sharedFiles = value;
      if (_sharedFiles != null && _sharedFiles!.isNotEmpty) {
        _shareChatMessage(_sharedFiles!.first);
      }
    });
  }

  ///myself和appDataProvider发生变化后刷新整个界面
  _update() async {
    if (mounted) {
      setState(() {});
    }
  }

  _updateConferenceJoined() {
    if (indexWidgetProvider.current == 'video_chat' ||
        indexWidgetProvider.current == 'sfu_video_chat') {
      return;
    }
    String? conferenceId = p2pConferenceClientPool.conferenceId;
    conferenceId ??= liveKitConferenceClientPool.conferenceId;
    if (conferenceId != null) {
      P2pConferenceClient? conferenceClient =
          p2pConferenceClientPool.conferenceClient;
      if (conferenceClient != null) {
        conferenceJoined.value = conferenceClient.joined;
      } else {
        LiveKitConferenceClient? liveKitConferenceClient =
            liveKitConferenceClientPool.conferenceClient;
        if (liveKitConferenceClient != null) {
          conferenceJoined.value = liveKitConferenceClient.joined;
        }
      }
    }
  }

  _play() {
    conferenceChatMessageController.playAudio(
        'assets/medias/invitation.mp3', true);
  }

  _stop() {
    conferenceChatMessageController.stopAudio();
  }

  ///有新消息到来的时候，一般消息直接显示
  _updateGlobalChatMessage(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    String senderPeerId = chatMessage.senderPeerId!;
    String? groupId = chatMessage.groupId;
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
    if (linkman != null) {
      bannerAvatarImage = linkman.avatarImage ?? AppImage.mdAppImage;
    }
    if (subMessageType == ChatMessageSubType.chat.name) {
      this.chatMessage = chatMessage;
      String? current = indexWidgetProvider.current;
      if (current != 'chat_message') {
        // if (mounted) {
        //   _buildChatMessageNotification(context);
        // }
        chatMessageVisible.value = true;
      } else {
        ChatSummary? chatSummary = chatMessageController.chatSummary;
        if (chatSummary == null) {
          // if (mounted) {
          //   _buildChatMessageNotification(context);
          // }
          chatMessageVisible.value = true;
        } else {
          String? peerId = chatSummary.peerId;
          if (senderPeerId != peerId && groupId != peerId) {
            // if (mounted) {
            //   _buildChatMessageNotification(context);
            // }
            chatMessageVisible.value = true;
          }
        }
      }
    }
    //新的视频邀请消息到来，创建新的视频消息控制器，原来的如果存在，新的将被忽视，占线
    if (subMessageType == ChatMessageSubType.videoChat.name) {
      if (!conferenceChatMessageVisible.value) {
        await conferenceChatMessageController.setChatMessage(chatMessage);
        conferenceChatMessageVisible.value = true;
      } else {
        ConferenceChatMessageController conferenceChatMessageController =
            ConferenceChatMessageController();
        await conferenceChatMessageController.setChatMessage(chatMessage);
        await conferenceChatMessageController
            .sendChatReceipt(MessageReceiptType.busy);
        await conferenceChatMessageController.terminate();
      }
    }
  }

  _buildChatMessageNotification(BuildContext context) {
    String? name = chatMessage!.senderName;
    Widget icon = Column(
      children: [
        bannerAvatarImage,
        Text(name ?? ''),
      ],
    );
    String? title = chatMessage!.title;
    Widget? titleWidget;
    if (title != null) {
      titleWidget = Text(title);
    }
    Widget contentWidget = Container();
    String? content = chatMessage!.content;
    String? contentType = chatMessage!.contentType;
    if (content != null &&
        (contentType == null ||
            contentType == ChatMessageContentType.text.name)) {
      content = chatMessageService.recoverContent(content);
      contentWidget = ExtendedText(
        content,
        specialTextSpanBuilder: customSpecialTextSpanBuilder,
      );
    }
    NotificationUtil.show(context,
        title: titleWidget, description: contentWidget, icon: icon);
  }

  ///显示视频聊天或者视频会议
  _buildVideoChatConferenceBanner(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: conferenceJoined,
        builder: (BuildContext context, bool conferenceJoined, Widget? child) {
          Widget banner = Container();
          ConferenceChatMessageController? conferenceChatMessageController;
          if (conferenceJoined) {
            P2pConferenceClient? conferenceClient =
                p2pConferenceClientPool.conferenceClient;
            if (conferenceClient != null) {
              conferenceChatMessageController =
                  conferenceClient.conferenceChatMessageController;
            } else {
              LiveKitConferenceClient? liveKitConferenceClient =
                  liveKitConferenceClientPool.conferenceClient;
              if (liveKitConferenceClient != null) {
                conferenceChatMessageController =
                    liveKitConferenceClient.conferenceChatMessageController;
              }
            }
            if (conferenceChatMessageController != null) {
              List<Widget> children = <Widget>[];
              String conferenceName =
                  conferenceChatMessageController.conferenceName ?? '';
              children.add(
                CommonAutoSizeText(conferenceName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              );
              String conferenceId =
                  conferenceChatMessageController.conferenceId ?? '';
              children.add(
                CommonAutoSizeText(
                  conferenceId,
                  style: const TextStyle(
                      fontSize: 14.0, fontWeight: FontWeight.w400),
                ),
              );
              String topic =
                  conferenceChatMessageController.conference?.topic ?? '';
              children.add(ExtendedText(
                topic,
                specialTextSpanBuilder: customSpecialTextSpanBuilder,
              ));
              bool sfu =
                  conferenceChatMessageController.conference?.sfu ?? true;
              banner = Column(children: [
                Container(
                    width: appDataProvider.totalSize.width,
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(10.0),
                    child: InkWell(
                        onTap: () async {
                          this.conferenceJoined.value = false;
                          if (sfu) {
                            indexWidgetProvider.push('sfu_video_chat');
                          } else {
                            indexWidgetProvider.push('video_chat');
                          }
                        },
                        child: Card(
                            elevation: 0.0,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 15.0,
                                  ),
                                  Icon(
                                    Icons.meeting_room,
                                    color: myself.primary,
                                  ),
                                  const SizedBox(
                                    width: 15.0,
                                  ),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: children)),
                                ])))),
                const Spacer()
              ]);
            }
          }
          return Visibility(
              visible: conferenceChatMessageController != null, child: banner);
        });
  }

  ///显示一般消息
  _buildChatMessageBanner(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: chatMessageVisible,
        builder: (BuildContext context, bool value, Widget? child) {
          Widget banner = Container();
          if (value) {
            if (chatMessage != null &&
                chatMessage!.subMessageType == ChatMessageSubType.chat.name) {
              List<Widget> children = <Widget>[];
              var name = chatMessage!.senderName;
              if (name != null) {
                children.add(
                  CommonAutoSizeText(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                );
              }
              String? title = chatMessage!.title;
              if (title != null) {
                children.add(
                  CommonAutoSizeText(
                    title,
                    style: const TextStyle(
                        fontSize: 14.0, fontWeight: FontWeight.w400),
                  ),
                );
              }
              String? content = chatMessage!.content;
              String? contentType = chatMessage!.contentType;
              if (content != null &&
                  (contentType == null ||
                      contentType == ChatMessageContentType.text.name)) {
                content = chatMessageService.recoverContent(content);
                children.add(ExtendedText(
                  content,
                  specialTextSpanBuilder: customSpecialTextSpanBuilder,
                ));
              }

              banner = Column(children: [
                Container(
                    width: appDataProvider.totalSize.width,
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(10.0),
                    child: InkWell(
                        onTap: () async {
                          chatMessageVisible.value = false;
                          chatMessage = null;
                          await conferenceChatMessageController.close();
                        },
                        child: Card(
                            elevation: 0.0,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 15.0,
                                  ),
                                  bannerAvatarImage,
                                  const SizedBox(
                                    width: 15.0,
                                  ),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: children)),
                                ])))),
                const Spacer()
              ]);

              //延时30秒后一般消息消失
              Future.delayed(const Duration(seconds: 15)).then((value) async {
                chatMessageVisible.value = false;
                chatMessage = null;
                await conferenceChatMessageController.close();
              });
            }
          }
          return Visibility(visible: value, child: banner);
        });
  }

  ///显示视频邀请消息组件
  Widget _buildVideoChatMessageWidget(BuildContext context) {
    ChatMessage? conferenceChatMessage =
        conferenceChatMessageController.chatMessage;
    if (conferenceChatMessage == null) {
      return Container();
    }
    if (conferenceChatMessage.subMessageType !=
        ChatMessageSubType.videoChat.name) {
      return Container();
    }
    var name = conferenceChatMessage.senderName;
    name = name ?? '';
    var title = conferenceChatMessage.title;
    title = title ?? '';
    String? topic;
    if (conferenceChatMessage.content != null) {
      var content =
          chatMessageService.recoverContent(conferenceChatMessage.content!);
      Map<String, dynamic> json = JsonUtil.toJson(content);
      var conference = Conference.fromJson(json);
      topic = conference.topic;
    }
    var rejectedButton = IconTextButton(
        label: AppLocalizations.t('Reject'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          await conferenceChatMessageController
              .sendChatReceipt(MessageReceiptType.rejected);
          conferenceChatMessageController.close();
        },
        icon: const Icon(color: Colors.red, size: 24, Icons.call_end));
    var receivedButton = IconTextButton(
        label: AppLocalizations.t('Receive'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          await conferenceChatMessageController
              .sendChatReceipt(MessageReceiptType.received);
          conferenceChatMessageController.close();
        },
        icon: const Icon(color: Colors.amber, size: 24, Icons.add_call));
    var ignoredButton = IconTextButton(
        label: AppLocalizations.t('Ignore'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          await conferenceChatMessageController
              .sendChatReceipt(MessageReceiptType.ignored);
          conferenceChatMessageController.close();
        },
        icon: const Icon(
            color: Colors.blue, size: 24, Icons.call_missed_outgoing));
    var acceptedButton = IconTextButton(
        label: AppLocalizations.t('Accept'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          P2pConferenceClient? p2pConferenceClient =
              await p2pConferenceClientPool
                  .createConferenceClient(conferenceChatMessage);
          ConferenceChatMessageController? conferenceChatMessageController =
              p2pConferenceClient?.conferenceChatMessageController;
          await conferenceChatMessageController
              ?.sendChatReceipt(MessageReceiptType.accepted);
          this.conferenceChatMessageController.close();
        },
        icon: const Icon(color: Colors.green, size: 24, Icons.call));
    List<Widget> buttons = <Widget>[];
    List<Widget> children = [];

    ///立即接听按钮只有当前不在会议中，而且是个人才可以
    if (conferenceChatMessage.groupId == null) {
      buttons.add(rejectedButton);
      buttons.add(acceptedButton);
    } else {
      buttons.add(ignoredButton);
      buttons.add(receivedButton);
    }
    if (p2pConferenceClientPool.conferenceId != null) {
      String? conferenceName = p2pConferenceClientPool
          .conferenceChatMessageController?.conference?.name;
      if (conferenceName != null) {
        children.add(
          CommonAutoSizeText(
            AppLocalizations.t('You are in conference:') + conferenceName,
            style: const TextStyle(color: Colors.amber),
          ),
        );
      }
    }
    children.addAll([
      CommonAutoSizeText(name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      CommonAutoSizeText(
        AppLocalizations.t('Inviting you $title chat ') +
            (conferenceChatMessage.senderName ?? ''),
      ),
      CommonAutoSizeText(
        '${AppLocalizations.t('Topic')}: ${topic ?? ''}',
      ),
      ButtonBar(alignment: MainAxisAlignment.end, children: buttons),
    ]);
    return Column(children: [
      Container(
          alignment: Alignment.topLeft,
          width: appDataProvider.totalSize.width,
          padding: const EdgeInsets.all(10.0),
          child: Card(
              elevation: 0.0,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                  width: 10.0,
                ),
                bannerAvatarImage,
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children)),
              ]))),
      const Spacer()
    ]);
  }

  ///显示视频邀请消息
  _buildVideoChatMessageBanner(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: conferenceChatMessageVisible,
      builder: (BuildContext context, bool value, Widget? child) {
        Widget videoChatMessageWidget = Container();
        if (value) {
          _play();
          ChatMessage? conferenceChatMessage =
              conferenceChatMessageController.chatMessage;
          if (conferenceChatMessage == null) {
            return Container();
          }
          //视频通话请求消息
          if (conferenceChatMessage.subMessageType ==
              ChatMessageSubType.videoChat.name) {
            videoChatMessageWidget = _buildVideoChatMessageWidget(context);
            //延时60秒后视频邀请消息消失，发送ignored回执
            Future.delayed(const Duration(seconds: 60)).then((value) async {
              _stop();
              if (conferenceChatMessageVisible.value) {
                conferenceChatMessageVisible.value = false;
                await conferenceChatMessageController
                    .sendChatReceipt(MessageReceiptType.received);
                conferenceChatMessageController.close();
              }
            });
          }
        }
        return Visibility(
            visible: conferenceChatMessageVisible.value,
            child: videoChatMessageWidget);
      },
    );
  }

  Future<void> _shareChatMessage(SharedFile file) async {
    String? content = file.value;
    String? thumbnail = file.thumbnail;
    SharedMediaType type = file.type;
    if (type == SharedMediaType.URL) {
      content = '#$content#';
    }
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return LinkmanGroupSearchWidget(
              onSelected: (List<String>? selected) async {
                if (selected != null && selected.isNotEmpty) {
                  String? receivePeerId;
                  Linkman? linkman =
                      await linkmanService.findCachedOneByPeerId(selected[0]);
                  if (linkman != null) {
                    receivePeerId = linkman.peerId;
                  } else {
                    Group? group =
                        await groupService.findCachedOneByPeerId(selected[0]);
                    if (group != null) {
                      receivePeerId = group.peerId;
                    }
                  }
                  if (receivePeerId != null) {
                    ChatSummary? current = await chatSummaryService
                        .findCachedOneByPeerId(receivePeerId);
                    if (current != null) {
                      chatMessageController.chatSummary = current;
                      indexWidgetProvider.push('chat_message');
                      if (type == SharedMediaType.TEXT ||
                          type == SharedMediaType.URL) {
                        ChatMessageContentType contentType =
                            ChatMessageContentType.text;
                        if (type == SharedMediaType.URL) {
                          contentType = ChatMessageContentType.url;
                        }
                        await chatMessageController.sendText(
                            message: content, contentType: contentType);
                      } else if (type == SharedMediaType.VIDEO ||
                          type == SharedMediaType.IMAGE ||
                          type == SharedMediaType.FILE) {
                        ChatMessageContentType contentType =
                            ChatMessageContentType.file;
                        if (type == SharedMediaType.VIDEO) {
                          contentType = ChatMessageContentType.video;
                        }
                        if (type == SharedMediaType.IMAGE) {
                          contentType = ChatMessageContentType.image;
                        }
                        String filename = content!;
                        Uint8List? data =
                            await FileUtil.readFileAsBytes(filename);
                        if (data != null) {
                          String? mimeType = FileUtil.mimeType(filename);
                          mimeType = mimeType ?? 'text/plain';
                          await chatMessageController.send(
                              title: filename,
                              content: data,
                              thumbnail: thumbnail,
                              contentType: contentType,
                              mimeType: mimeType);
                        }
                      }
                    }
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              selected: const <String>[],
              selectType: SelectType.chipMultiSelect);
        });
  }

  Widget _createScaffold(
      BuildContext context, IndexWidgetProvider indexWidgetProvider) {
    double width = appDataProvider.totalSize.width;
    double height = appDataProvider.totalSize.height;
    if (!appDataProvider.landscape) {
      width = appDataProvider.portraitSize.width;
      height = appDataProvider.portraitSize.height;
    }
    Scaffold scaffold = Scaffold(
      resizeToAvoidBottomInset: true,
      primary: true,
      appBar:
          AppBarWidget.buildAppBar(context, toolbarHeight: 0.0, elevation: 0.0),
      body: KeyboardDismissOnTap(
          dismissOnCapturedTaps: false,
          child: SafeArea(
              child: Stack(children: <Widget>[
            Opacity(
              opacity: 1,
              child: loadingWidget,
            ),
            Center(
                child: platformWidgetFactory.sizedBox(
                    child: widget.adaptiveLayoutIndex,
                    height: height,
                    width: width)),
            Row(children: [
              _buildVideoChatConferenceBanner(context),
              _buildChatMessageBanner(context),
              _buildVideoChatMessageBanner(context)
            ]),
          ]))),
    );

    return scaffold;
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var provider = Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(
        builder:
            (context, appDataProvider, indexWidgetProvider, myself, child) {
      return _createScaffold(context, indexWidgetProvider);
    });
    return provider;
  }

  @override
  void dispose() {
    chatMessageStreamSubscription?.cancel();
    chatMessageStreamSubscription = null;
    myself.removeListener(_update);
    appDataProvider.removeListener(_update);
    _intentDataStreamSubscription?.cancel();
    _intentDataStreamSubscription = null;
    globalWebrtcEvent.onWebrtcSignal = null;
    errorWebrtcEventStreamSubscription?.cancel();
    errorWebrtcEventStreamSubscription = null;
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    super.dispose();
  }
}
