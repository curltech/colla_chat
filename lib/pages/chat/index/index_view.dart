import 'dart:async';
import 'dart:typed_data';

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
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
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
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';

class IndexView extends StatefulWidget {
  final String title;
  final AdaptiveLayoutIndex adaptiveLayoutIndex = AdaptiveLayoutIndex();

  IndexView({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IndexViewState();
  }
}

class _IndexViewState extends State<IndexView>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> conferenceChatMessageVisible =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> chatMessageVisible = ValueNotifier<bool>(false);
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();
  ChatMessage? chatMessage;
  ChatMessage? conferenceChatMessage;
  BlueFireAudioPlayer? audioPlayer;

  //JustAudioPlayer audioPlayer = JustAudioPlayer();
  Widget bannerAvatarImage = AppImage.mdAppImage;

  StreamSubscription? _intentDataStreamSubscription;
  List<SharedFile>? _sharedFiles;

  @override
  void initState() {
    super.initState();
    _initShare();
    try {
      audioPlayer = BlueFireAudioPlayer();
    } catch (e) {
      logger.e('BlueFireAudioPlayer create error:$e');
    }
    globalChatMessageController.addListener(_updateGlobalChatMessage);
    myself.addListener(_update);
    appDataProvider.addListener(_update);
    globalWebrtcEventController.onWebrtcSignal = _onWebrtcSignal;
    globalWebrtcEventController.onWebrtcErrorSignal = _onWebrtcErrorSignal;

    _initSystemTray();
  }

  Future<bool?> _onWebrtcSignal(WebrtcEvent webrtcEvent) async {
    String peerId = webrtcEvent.peerId;
    String name = webrtcEvent.name;
    WebrtcEventType eventType = webrtcEvent.eventType;

    return await DialogUtil.confirm(context,
        content: name +
            AppLocalizations.t(
                ' is a stranger, want to chat with you, are you agree?'));
  }

  Future<void> _onWebrtcErrorSignal(WebrtcEvent webrtcEvent) async {
    String peerId = webrtcEvent.peerId;
    String name = webrtcEvent.name;
    String clientId = webrtcEvent.clientId;
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

  _play() {
    audioPlayer?.setLoopMode(true);
    audioPlayer?.play('assets/medias/invitation.mp3');
  }

  _stop() {
    audioPlayer?.stop();
    audioPlayer?.release();
  }

  ///有新消息到来的时候，一般消息直接显示
  _updateGlobalChatMessage() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage == null) {
      this.chatMessage = null;
      conferenceChatMessage = null;
      return;
    }
    String? subMessageType = chatMessage.subMessageType;
    if (ChatMessageSubType.videoChat.name == subMessageType) {
      conferenceChatMessage = chatMessage;
    }
    String senderPeerId = chatMessage.senderPeerId!;
    String? groupId = chatMessage.groupId;
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
    if (linkman != null) {
      bannerAvatarImage = linkman.avatarImage ?? AppImage.mdAppImage;
    }
    if (chatMessage.subMessageType == ChatMessageSubType.chat.name) {
      this.chatMessage = chatMessage;
      String? current = indexWidgetProvider.current;
      if (current != 'chat_message') {
        chatMessageVisible.value = true;
      } else {
        ChatSummary? chatSummary = chatMessageController.chatSummary;
        if (chatSummary == null) {
          chatMessageVisible.value = true;
        } else {
          String? peerId = chatSummary.peerId;
          if (senderPeerId != peerId && groupId != peerId) {
            chatMessageVisible.value = true;
          }
        }
      }
    }
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
                      softWrap: true,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                );
              }
              String? title = chatMessage!.title;
              if (title != null) {
                children.add(
                  CommonAutoSizeText(title,
                      softWrap: true,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w400)),
                );
              }
              String? content = chatMessage!.content;
              String? contentType = chatMessage!.contentType;
              if (content != null &&
                  (contentType == null ||
                      contentType == ChatMessageContentType.text.name)) {
                content = chatMessageService.recoverContent(content);
                children.add(Expanded(
                    child: ExtendedText(
                  content,
                  softWrap: true,
                  style: const TextStyle(
                      //fontSize: 16.0,
                      ),
                  specialTextSpanBuilder: customSpecialTextSpanBuilder,
                )));
              }

              banner = InkWell(
                  onTap: () {
                    chatMessageVisible.value = false;
                  },
                  child: Container(
                      height: appDataProvider.toolbarHeight,
                      width: appDataProvider.totalSize.width,
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(5.0),
                      color: Colors.black.withOpacity(AppOpacity.mdOpacity),
                      child: Card(
                          elevation: 0.0,
                          margin: EdgeInsets.zero,
                          shape: const ContinuousRectangleBorder(),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                bannerAvatarImage,
                                const SizedBox(
                                  width: 15.0,
                                ),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: children),
                              ]))));

              //延时30秒后一般消息消失
              Future.delayed(const Duration(seconds: 30)).then((value) {
                chatMessageVisible.value = false;
              });
            }
          }
          return Visibility(visible: value, child: banner);
        });
  }

  ///显示视频邀请消息组件
  Widget _buildVideoChatMessageWidget(
      BuildContext context, ChatMessage chatMessage) {
    var name = chatMessage.senderName;
    name = name ?? '';
    var title = chatMessage.title;
    title = title ?? '';
    String? topic;
    if (chatMessage.content != null) {
      var content = chatMessageService.recoverContent(chatMessage.content!);
      Map<String, dynamic> json = JsonUtil.toJson(content);
      var conference = Conference.fromJson(json);
      topic = conference.topic;
    }
    var rejectedButton = IconButton(
        tooltip: AppLocalizations.t('Reject'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          ConferenceChatMessageController conferenceChatMessageController =
              ConferenceChatMessageController();
          await conferenceChatMessageController.setChatMessage(chatMessage);
          await conferenceChatMessageController
              .sendChatReceipt(MessageReceiptType.rejected);
          conferenceChatMessageController.terminate();
        },
        icon: const Icon(color: Colors.red, size: 24, Icons.call_end));
    var holdButton = IconButton(
        tooltip: AppLocalizations.t('Hold'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          P2pConferenceClient? p2pConferenceClient =
              await p2pConferenceClientPool
                  .createP2pConferenceClient(chatMessage);
          ConferenceChatMessageController? conferenceChatMessageController =
              p2pConferenceClient?.conferenceChatMessageController;
          await conferenceChatMessageController
              ?.sendChatReceipt(MessageReceiptType.hold);
        },
        icon: const Icon(color: Colors.amber, size: 24, Icons.add_call));
    var acceptedButton = IconButton(
        tooltip: AppLocalizations.t('Accept'),
        onPressed: () async {
          conferenceChatMessageVisible.value = false;
          _stop();
          P2pConferenceClient? p2pConferenceClient =
              await p2pConferenceClientPool
                  .createP2pConferenceClient(chatMessage);
          ConferenceChatMessageController? conferenceChatMessageController =
              p2pConferenceClient?.conferenceChatMessageController;
          await conferenceChatMessageController
              ?.sendChatReceipt(MessageReceiptType.accepted);
        },
        icon: const Icon(color: Colors.green, size: 24, Icons.call));
    List<Widget> buttons = <Widget>[];
    buttons.add(rejectedButton);
    buttons.add(holdButton);

    ///立即接听按钮只有当前不在会议中，而且是个人或者群模式才可以
    if (p2pConferenceClientPool.conferenceId == null &&
        chatMessage.groupType != PartyType.conference.name) {
      buttons.add(acceptedButton);
    }
    return Container(
        height: 148,
        alignment: Alignment.topLeft,
        width: appDataProvider.totalSize.width,
        padding: const EdgeInsets.all(10.0),
        child: Card(
            elevation: 0.0,
            margin: EdgeInsets.zero,
            shape: const ContinuousRectangleBorder(),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              bannerAvatarImage,
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    CommonAutoSizeText(name,
                        softWrap: true,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                        child: CommonAutoSizeText(
                      AppLocalizations.t('Inviting you $title chat ') +
                          (chatMessage.senderName ?? ''),
                      softWrap: true,
                    )),
                    CommonAutoSizeText(
                      '${AppLocalizations.t('Topic:')} ${topic ?? ''}',
                      softWrap: true,
                    ),
                    ButtonBar(
                        alignment: MainAxisAlignment.end, children: buttons),
                  ])),
            ])));
  }

  _buildVideoChatMessageBanner(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: conferenceChatMessageVisible,
      builder: (BuildContext context, bool value, Widget? child) {
        Widget videoChatMessageWidget = Container();
        if (value) {
          _play();
          if (conferenceChatMessage != null) {
            //视频通话请求消息
            if (conferenceChatMessage!.subMessageType ==
                ChatMessageSubType.videoChat.name) {
              videoChatMessageWidget =
                  _buildVideoChatMessageWidget(context, conferenceChatMessage!);
              //延时60秒后视频邀请消息消失，发送ignored回执
              Future.delayed(const Duration(seconds: 60)).then((value) async {
                _stop();
                if (conferenceChatMessageVisible.value) {
                  conferenceChatMessageVisible.value = false;
                  ConferenceChatMessageController
                      conferenceChatMessageController =
                      ConferenceChatMessageController();
                  await conferenceChatMessageController
                      .setChatMessage(conferenceChatMessage!);
                  await conferenceChatMessageController
                      .sendChatReceipt(MessageReceiptType.ignored);
                  conferenceChatMessageController.terminate();
                }
              });
            }
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
      appBar: AppBar(toolbarHeight: 0.0, elevation: 0.0),
      body: KeyboardDismissOnTap(
          dismissOnCapturedTaps: false,
          child: SafeArea(
              child: Stack(children: <Widget>[
            Opacity(
              opacity: 1,
              child: loadingWidget,
            ),
            Center(
                child: platformWidgetFactory.buildSizedBox(
                    child: widget.adaptiveLayoutIndex,
                    height: height,
                    width: width)),
            Row(children: [
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
      builder: (context, appDataProvider, indexWidgetProvider, myself, child) =>
          _createScaffold(context, indexWidgetProvider),
    );
    return provider;
  }

  @override
  void dispose() {
    globalChatMessageController.removeListener(_updateGlobalChatMessage);
    myself.removeListener(_update);
    appDataProvider.removeListener(_update);
    _intentDataStreamSubscription?.cancel();
    globalWebrtcEventController.onWebrtcSignal = null;
    globalWebrtcEventController.onWebrtcErrorSignal = null;
    _stop();
    super.dispose();
  }
}
