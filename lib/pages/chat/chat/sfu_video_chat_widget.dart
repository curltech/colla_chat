import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_local_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_remote_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_video_conference_pool_widget.dart';
import 'package:colla_chat/pages/chat/chat/video_chat_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///Sfu视频聊天窗口，分页显示本地视频和远程视频
class SfuVideoChatWidget extends StatefulWidget with TileDataMixin {
  final SfuLocalVideoWidget sfuLocalVideoWidget = const SfuLocalVideoWidget();
  final SfuRemoteVideoWidget sfuRemoteVideoWidget =
      const SfuRemoteVideoWidget();
  final SfuVideoConferencePoolWidget sfuVideoConferencePoolWidget =
      SfuVideoConferencePoolWidget();

  SfuVideoChatWidget({
    super.key,
  }) {
    indexWidgetProvider.define(sfuVideoConferencePoolWidget);
  }

  @override
  State<StatefulWidget> createState() {
    return _SfuVideoChatWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_video_chat';

  @override
  IconData get iconData => Icons.video_call;

  @override
  String get title => 'SfuVideoChat';

  
}

class _SfuVideoChatWidgetState extends State<SfuVideoChatWidget> {
  ValueNotifier<ConferenceChatMessageController?>
      conferenceChatMessageController =
      ValueNotifier<ConferenceChatMessageController?>(
          liveKitConferenceClientPool.conferenceChatMessageController);
  ChatSummary chatSummary = chatMessageController.chatSummary!;
  SwiperController swiperController = SwiperController();
  ValueNotifier<int> index = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    liveKitConferenceClientPool.addListener(_update);
    videoChatDragOverlay.dispose();
  }

  _update() {
    conferenceChatMessageController.value =
        liveKitConferenceClientPool.conferenceChatMessageController;
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Swiper(
      controller: swiperController,
      itemCount: 2,
      index: index.value,
      itemBuilder: (BuildContext context, int index) {
        Widget view = widget.sfuLocalVideoWidget;
        if (index == 1) {
          view = widget.sfuRemoteVideoWidget;
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
          return nilBox;
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
          return nilBox;
        },
      );
      rightWidgets.add(remote);
    }
    if (myself.peerProfile.developerSwitch) {
      rightWidgets.add(IconButton(
        onPressed: () {
          indexWidgetProvider.push('sfu_video_conference_pool');
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
      helpPath: widget.routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      leadingCallBack: () {
        bool? joined = liveKitConferenceClientPool.conferenceClient?.joined;
        if (joined != null && joined) {
          videoChatDragOverlay.show(context);
        }
      },
      child: videoChatView,
    );
  }

  Widget _buildTitleWidget(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: conferenceChatMessageController,
        builder: (BuildContext context,
            ConferenceChatMessageController? videoChatMessageController,
            Widget? child) {
          String title = widget.title;
          ChatSummary chatSummary = this.chatSummary;
          String? peerName;
          peerName = chatSummary.name;
          peerName ??= '';
          if (chatSummary.partyType == PartyType.conference.name) {
            //title = 'VideoConference';
          }
          title = '${AppLocalizations.t(title)} - $peerName';
          if (videoChatMessageController != null &&
              videoChatMessageController.conferenceName != null &&
              chatSummary.partyType != PartyType.conference.name) {
            title = '$title\n${videoChatMessageController.conferenceName}';
          }

          Widget titleWidget = AutoSizeText(title, maxLines: 2);

          return titleWidget;
        });
  }

  @override
  void dispose() {
    liveKitConferenceClientPool.removeListener(_update);
    super.dispose();
  }
}
