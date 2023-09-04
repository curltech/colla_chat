import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/video/remote_video_widget.dart';
import 'package:colla_chat/pages/chat/video/video_conference_pool_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/drag_overlay.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///视频聊天窗口，分页显示本地视频和远程视频
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  DragOverlay? overlayEntry;
  final LocalVideoWidget localVideoWidget = const LocalVideoWidget();
  final RemoteVideoWidget remoteVideoWidget = const RemoteVideoWidget();
  final VideoConferencePoolWidget videoConferencePoolWidget =
      const VideoConferencePoolWidget();

  VideoChatWidget({
    Key? key,
  }) : super(key: key);

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
  ValueNotifier<ConferenceChatMessageController?> videoChatMessageController =
      ValueNotifier<ConferenceChatMessageController?>(
          p2pConferenceClientPool.conferenceChatMessageController);
  ChatSummary chatSummary = chatMessageController.chatSummary!;
  SwiperController swiperController = SwiperController();
  int index = 0;

  @override
  void initState() {
    super.initState();
    //如果此时overlay界面存在
    if (widget.overlayEntry != null) {
      widget.overlayEntry!.dispose();
      widget.overlayEntry = null;
    }
    p2pConferenceClientPool.addListener(_update);
  }

  _update() {
    videoChatMessageController.value =
        p2pConferenceClientPool.conferenceChatMessageController;
  }

  ///关闭最小化界面，把本界面显示
  _closeOverlayEntry() {
    if (widget.overlayEntry != null) {
      widget.overlayEntry!.dispose();
      widget.overlayEntry = null;
      indexWidgetProvider.currentMainIndex = 0;
      indexWidgetProvider.push('chat_message');
      indexWidgetProvider.push('video_chat');
    }
  }

  ///最小化界面，将overlay按钮压入，本界面被弹出
  _minimize(BuildContext context) {
    widget.overlayEntry = DragOverlay(
      child: CircleTextButton(
          padding: const EdgeInsets.all(15.0),
          backgroundColor: myself.primary,
          onPressed: () {
            _closeOverlayEntry();
          },
          child: const Icon(size: 32, color: Colors.white, Icons.zoom_out_map)),
    );
    widget.overlayEntry!.show(context: context);
    indexWidgetProvider.pop();
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Swiper(
      controller: swiperController,
      itemCount: 3,
      index: index,
      itemBuilder: (BuildContext context, int index) {
        Widget view = widget.localVideoWidget;
        if (index == 1) {
          view = widget.remoteVideoWidget;
        }
        if (index == 2) {
          view = widget.videoConferencePoolWidget;
        }
        return view;
      },
      onIndexChanged: (int index) {
        this.index = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    rightWidgets.add(IconButton(
      onPressed: () {
        swiperController.move(0);
      },
      icon: const Icon(Icons.local_library),
      tooltip: AppLocalizations.t('Local'),
    ));
    rightWidgets.add(IconButton(
      onPressed: () {
        swiperController.move(1);
      },
      icon: const Icon(Icons.devices_other),
      tooltip: AppLocalizations.t('Remote'),
    ));
    rightWidgets.add(IconButton(
      onPressed: () {
        swiperController.move(2);
      },
      icon: const Icon(Icons.list),
      tooltip: AppLocalizations.t('Conference pool'),
    ));

    rightWidgets.add(IconButton(
      onPressed: () {
        _minimize(context);
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
      child: videoChatView,
    );
  }

  Widget _buildTitleWidget(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: videoChatMessageController,
        builder: (BuildContext context,
            ConferenceChatMessageController? videoChatMessageController,
            Widget? child) {
          var chatSummary = this.chatSummary;
          var peerName = '';
          peerName = chatSummary.name!;
          String title = widget.title;
          if (chatSummary.partyType == PartyType.conference.name) {
            //title = 'VideoConference';
          }
          title = '${AppLocalizations.t(title)} - $peerName';
          if (videoChatMessageController != null &&
              videoChatMessageController.conferenceName != null &&
              chatSummary.partyType != PartyType.conference.name) {
            title = '$title${videoChatMessageController.conferenceName}';
          }

          Widget titleWidget = CommonAutoSizeText(title);

          return titleWidget;
        });
  }

  @override
  void dispose() {
    p2pConferenceClientPool.removeListener(_update);
    super.dispose();
  }
}
