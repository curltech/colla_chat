import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/video/remote_video_widget.dart';
import 'package:colla_chat/pages/chat/video/video_conference_pool_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/drag_overlay.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///视频聊天窗口，分页显示本地视频和远程视频
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  DragOverlay? overlayEntry;

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
  @override
  void initState() {
    super.initState();
    //如果此时overlay界面存在
    if (widget.overlayEntry != null) {
      widget.overlayEntry!.dispose();
      widget.overlayEntry = null;
    }
  }

  Future<VideoChatMessageController> _getVideoChatMessageController() async {
    //优先展示当前活动的会议，其次是有当前视频邀请消息的会议，最后是准备创建的会议
    var videoChatMessageController =
        videoConferenceRenderPool.videoChatMessageController;
    if (videoChatMessageController != null) {
      return videoChatMessageController;
    }
    //当前无激活的会议，创建基于当前聊天的视频消息控制器
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    ChatMessage? chatMessage = chatMessageController.current;
    if (chatMessage != null &&
        chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
      videoChatMessageController = videoConferenceRenderPool
          .getVideoChatMessageController(chatMessage.messageId!);
    }
    if (videoChatMessageController == null) {
      videoChatMessageController = VideoChatMessageController();
      await videoChatMessageController.setChatSummary(chatSummary);
      await videoChatMessageController.setChatMessage(chatMessage);
    }

    return videoChatMessageController;
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
      child: WidgetUtil.buildCircleButton(
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

  Widget _buildVideoChatView(BuildContext context,
      VideoChatMessageController videoChatMessageController) {
    return Swiper(
      controller: SwiperController(),
      itemCount: 3,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        Widget view = LocalVideoWidget(
            videoChatMessageController: videoChatMessageController);
        if (index == 1) {
          view = RemoteVideoWidget(
              videoChatMessageController: videoChatMessageController);
        }
        if (index == 2) {
          view = const VideoConferencePoolWidget();
        }
        return view;
      },
      onIndexChanged: (int index) {
        logger.i('changed to index $index');
      },
      // pagination: SwiperPagination(
      //     builder: DotSwiperPaginationBuilder(
      //   activeColor: myself.primary,
      //   color: Colors.white,
      //   activeSize: 15,)
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
          onPressed: () {
            _minimize(context);
          },
          icon: const Icon(Icons.zoom_in_map, color: Colors.white)),
    ];
    return FutureBuilder(
        future: _getVideoChatMessageController(),
        builder: (BuildContext context,
            AsyncSnapshot<VideoChatMessageController> snapshot) {
          Widget videoChatView = Center(
              child: Text(AppLocalizations.t(
                  'VideoChatMessageController is not ready')));
          if (!snapshot.hasData || snapshot.data == null) {
            return videoChatView;
          }
          VideoChatMessageController videoChatMessageController =
              snapshot.data!;
          var peerName = '';
          var chatSummary = chatMessageController.chatSummary;
          if (chatSummary != null) {
            peerName = chatSummary.name!;
            videoChatView =
                _buildVideoChatView(context, videoChatMessageController);
          }
          String title = widget.title;
          if (chatSummary!.partyType == PartyType.conference.name) {
            title = 'VideoConference';
          }
          Widget titleWidget = Text('${AppLocalizations.t(title)} - $peerName');
          if (videoChatMessageController.conferenceName != null &&
              chatSummary.partyType != PartyType.conference.name) {
            titleWidget = Column(children: [
              titleWidget,
              Text('${videoChatMessageController.conferenceName}',
                  style: const TextStyle(fontSize: 12))
            ]);
          }
          return AppBarView(
            titleWidget: titleWidget,
            withLeading: true,
            rightWidgets: rightWidgets,
            child: videoChatView,
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
