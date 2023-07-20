import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
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
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
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
  final ValueNotifier<bool> videoChatMessageVisible =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> chatMessageVisible = ValueNotifier<bool>(false);
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();
  VideoChatMessageController? videoChatMessageController;
  BlueFireAudioPlayer? audioPlayer;

  //JustAudioPlayer audioPlayer = JustAudioPlayer();
  Widget bannerAvatarImage = AppImage.mdAppImage;

  late StreamSubscription _intentDataStreamSubscription;
  late List<SharedFile> _sharedFiles;

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
      if (_sharedFiles.isNotEmpty) {
        _shareChatMessage(_sharedFiles.first);
      }
    }, onError: (err) {
      logger.e("getIntentDataStream error: $err");
    });

    // 应用关闭时分享的媒体文件
    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((List<SharedFile> value) {
      _sharedFiles = value;
      if (_sharedFiles.isNotEmpty) {
        _shareChatMessage(_sharedFiles.first);
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
  }

  ///有新消息到来的时候，一般消息直接显示
  _updateGlobalChatMessage() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      String senderPeerId = chatMessage.senderPeerId!;
      String? groupId = chatMessage.groupId;
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(senderPeerId);
      if (linkman != null) {
        bannerAvatarImage = linkman.avatarImage ?? AppImage.mdAppImage;
      }
      if (chatMessage.subMessageType == ChatMessageSubType.chat.name) {
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
      //新的视频邀请消息到来，创建新的视频消息控制器，原来的如果存在，新的将被忽视，占线
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        if (videoChatMessageController == null) {
          videoChatMessageController = VideoChatMessageController();
          await videoChatMessageController!.setChatMessage(chatMessage);
          videoChatMessageVisible.value = true;
        } else {
          var videoChatMessageController = VideoChatMessageController();
          await videoChatMessageController.setChatMessage(chatMessage);
          await videoChatMessageController
              .sendChatReceipt(MessageReceiptType.busy);
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
            ChatMessage? chatMessage = globalChatMessageController.chatMessage;
            if (chatMessage != null &&
                chatMessage.subMessageType == ChatMessageSubType.chat.name) {
              List<Widget> children = <Widget>[];
              var name = chatMessage.senderName;
              if (name != null) {
                children.add(
                  CommonAutoSizeText(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                );
              }
              String? title = chatMessage.title;
              if (title != null) {
                children.add(
                  CommonAutoSizeText(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                );
              }
              String? content = chatMessage.content;
              String? contentType = chatMessage.contentType;
              if (content != null &&
                  (contentType == null ||
                      contentType == ChatMessageContentType.text.name)) {
                content = chatMessageService.recoverContent(content);
                children.add(Expanded(
                    child: ExtendedText(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
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
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            bannerAvatarImage,
                            const SizedBox(
                              width: 15.0,
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children),
                          ])));

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
    var rejectedButton = CircleTextButton(
        onPressed: () async {
          videoChatMessageVisible.value = false;
          _stop();
          await videoChatMessageController!
              .sendChatReceipt(MessageReceiptType.rejected);
          videoChatMessageController = null;
        },
        backgroundColor: Colors.red,
        child: const Icon(color: Colors.white, size: 16, Icons.call_end));
    var holdButton = CircleTextButton(
        onPressed: () async {
          videoChatMessageVisible.value = false;
          _stop();
          await videoChatMessageController!
              .sendChatReceipt(MessageReceiptType.hold);
          videoChatMessageController = null;
        },
        backgroundColor: Colors.amber,
        child: const Icon(color: Colors.white, size: 16, Icons.add_call));
    var acceptedButton = CircleTextButton(
        onPressed: () async {
          videoChatMessageVisible.value = false;
          _stop();
          await videoChatMessageController!
              .sendChatReceipt(MessageReceiptType.accepted);
          videoChatMessageController = null;
        },
        backgroundColor: Colors.green,
        child: const Icon(color: Colors.white, size: 16, Icons.call));
    List<Widget> buttons = <Widget>[];
    buttons.add(rejectedButton);
    buttons.add(holdButton);
    //立即接听按钮只有当前不在会议中，而且是个人或者群模式才可以
    if (videoConferenceRenderPool.conferenceId == null &&
        chatMessage.groupType != PartyType.conference.name) {
      buttons.add(acceptedButton);
    }
    return Container(
        alignment: Alignment.topLeft,
        width: appDataProvider.totalSize.width,
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(AppOpacity.mdOpacity),
        child: ListTile(
            leading: bannerAvatarImage,
            isThreeLine: false,
            title: CommonAutoSizeText(name,
                style: const TextStyle(color: Colors.white)),
            subtitle: CommonAutoSizeText(
                AppLocalizations.t('Inviting you $title chat ') +
                    videoChatMessageController!.conference!.name,
                style: const TextStyle(color: Colors.white)),
            trailing: SizedBox(
              width: 200,
              child: Row(children: buttons),
            )));
  }

  _buildVideoChatMessageBanner(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: videoChatMessageVisible,
      builder: (BuildContext context, bool value, Widget? child) {
        Widget videoChatMessageWidget = Container();
        if (value) {
          _play();
          ChatMessage? chatMessage = videoChatMessageController!.chatMessage;
          if (chatMessage != null) {
            //视频通话请求消息
            if (chatMessage.subMessageType ==
                ChatMessageSubType.videoChat.name) {
              videoChatMessageWidget =
                  _buildVideoChatMessageWidget(context, chatMessage);
              //延时60秒后视频邀请消息消失，发送ignored回执
              Future.delayed(const Duration(seconds: 60)).then((value) async {
                _stop();
                if (videoChatMessageVisible.value) {
                  videoChatMessageVisible.value = false;
                  await videoChatMessageController!
                      .sendChatReceipt(MessageReceiptType.ignored);
                  videoChatMessageController?.dispose();
                  videoChatMessageController = null;
                }
              });
            }
          }
        }
        return Visibility(
            visible: videoChatMessageVisible.value,
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
    _intentDataStreamSubscription.cancel();
    globalWebrtcEventController.onWebrtcSignal = null;
    globalWebrtcEventController.onWebrtcErrorSignal = null;
    super.dispose();
  }
}
