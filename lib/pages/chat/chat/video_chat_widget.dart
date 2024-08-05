import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/local_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/remote_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/video_conference_pool_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/overlay/drag_overlay.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 可以浮动的按钮，激活当前视频会议，全局唯一，没有当前视频会议的时候不显示
class VideoChatDragOverlay {
  DragOverlay? overlayEntry;

  dispose() {
    if (overlayEntry != null) {
      overlayEntry!.close();
      overlayEntry = null;
    }
  }

  ///关闭最小化界面，把本界面显示
  hide() {
    if (overlayEntry != null) {
      String? target;
      ConferenceChatMessageController? conferenceChatMessageController =
          liveKitConferenceClientPool.conferenceChatMessageController;
      if (conferenceChatMessageController != null) {
        target = 'sfu_video_chat';
      } else {
        conferenceChatMessageController =
            p2pConferenceClientPool.conferenceChatMessageController;
        if (conferenceChatMessageController != null) {
          target = 'video_chat';
        }
      }
      if (conferenceChatMessageController != null) {
        ChatSummary? chatSummary = conferenceChatMessageController.chatSummary;
        if (chatSummary != null) {
          chatMessageController.chatSummary = chatSummary;
        }
      }
      if (target != null) {
        indexWidgetProvider.currentMainIndex = 0;
        indexWidgetProvider.push('chat_message');
        indexWidgetProvider.push(target);
      }
    }
  }

  ///最小化界面，将overlay按钮压入，本界面被弹出
  show(BuildContext context) {
    bool? joined = liveKitConferenceClientPool.conferenceClient?.joined;
    if (joined == null || !joined) {
      joined = p2pConferenceClientPool.conferenceClient?.joined;
    }
    if (joined != null && joined) {
      if (overlayEntry != null) {
        overlayEntry!.show(context);
      } else {
        overlayEntry = DragOverlay(
          child: CircleTextButton(
              padding: const EdgeInsets.all(15.0),
              backgroundColor: myself.primary,
              onPressed: () {
                hide();
              },
              label: AppLocalizations.t('Conference'),
              child: const Icon(
                  size: 32, color: Colors.yellow, Icons.zoom_out_map)),
        );
        overlayEntry!.show(context);
      }
    } else {
      dispose();
    }
  }
}

final VideoChatDragOverlay videoChatDragOverlay = VideoChatDragOverlay();

///视频聊天窗口，分页显示本地视频和远程视频
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  final LocalVideoWidget localVideoWidget = const LocalVideoWidget();
  final RemoteVideoWidget remoteVideoWidget = const RemoteVideoWidget();
  final VideoConferencePoolWidget videoConferencePoolWidget =
      VideoConferencePoolWidget();

  VideoChatWidget({
    super.key,
  }) {
    indexWidgetProvider.define(videoConferencePoolWidget);
  }

  @override
  State<StatefulWidget> createState() {
    return _VideoChatWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_chat';

  @override
  IconData get iconData => Icons.video_call;

  @override
  String get title => 'VideoChat';
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  ChatSummary chatSummary = chatMessageController.chatSummary!;
  SwiperController swiperController = SwiperController();
  ValueNotifier<int> index = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    p2pConferenceClientPool.addListener(_update);
    videoChatDragOverlay.dispose();
  }

  _update() {
    setState(() {});
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Swiper(
      controller: swiperController,
      itemCount: 2,
      index: index.value,
      itemBuilder: (BuildContext context, int index) {
        Widget view = widget.localVideoWidget;
        if (index == 1) {
          view = widget.remoteVideoWidget;
        }
        return view;
      },
      onIndexChanged: (int index) {
        this.index.value = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    if (platformParams.desktop) {
      Widget local = ValueListenableBuilder(
        valueListenable: index,
        builder: (BuildContext context, int value, Widget? child) {
          if (value == 1) {
            return IconButton(
              onPressed: () {
                swiperController.move(0);
              },
              icon: const Icon(Icons.local_library),
              tooltip: AppLocalizations.t('Local'),
            );
          }
          return nil;
        },
      );
      rightWidgets.add(local);
      Widget remote = ValueListenableBuilder(
        valueListenable: index,
        builder: (BuildContext context, int value, Widget? child) {
          if (value == 0) {
            return IconButton(
              onPressed: () {
                swiperController.move(1);
              },
              icon: const Icon(Icons.devices_other),
              tooltip: AppLocalizations.t('Remote'),
            );
          }
          return nil;
        },
      );
      rightWidgets.add(remote);
    }
    if (myself.peerProfile.developerSwitch) {
      rightWidgets.add(IconButton(
        onPressed: () {
          indexWidgetProvider.push('video_conference_pool');
        },
        icon: const Icon(Icons.list),
        tooltip: AppLocalizations.t('Conference pool'),
      ));
    }

    rightWidgets.add(IconButton(
      onPressed: () {
        videoChatDragOverlay.show(context);
        indexWidgetProvider.pop();
      },
      icon: const Icon(Icons.zoom_in_map),
      tooltip: AppLocalizations.t('Minimize'),
    ));

    Widget videoChatView = _buildVideoChatView(context);
    Widget titleWidget = _buildTitleWidget(context);
    return AppBarView(
      titleWidget: titleWidget,
      withLeading: true,
      rightWidgets: rightWidgets,
      leadingCallBack: () {
        bool? joined = p2pConferenceClientPool.conferenceClient?.joined;
        if (joined != null && joined) {
          videoChatDragOverlay.show(context);
        }
      },
      child: videoChatView,
    );
  }

  Widget _buildTitleWidget(BuildContext context) {
    ConferenceChatMessageController? conferenceChatMessageController =
        p2pConferenceClientPool.conferenceChatMessageController;
    String title = widget.title;
    ChatSummary chatSummary = this.chatSummary;
    String? peerName;
    peerName = chatSummary.name;
    peerName ??= '';
    if (chatSummary.partyType == PartyType.conference.name) {
      //title = 'VideoConference';
    }
    title = '${AppLocalizations.t(title)} - $peerName';
    if (conferenceChatMessageController != null &&
        conferenceChatMessageController.conferenceName != null &&
        chatSummary.partyType != PartyType.conference.name) {
      title = '$title\n${conferenceChatMessageController.conferenceName}';
    }

    Widget titleWidget = CommonAutoSizeText(title, maxLines: 2);

    return titleWidget;
  }

  @override
  void dispose() {
    p2pConferenceClientPool.removeListener(_update);
    super.dispose();
  }
}
