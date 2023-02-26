import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/video/remote_video_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///视频聊天窗口，分页显示本地视频和远程视频
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  const VideoChatWidget({
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
  OverlayEntry? overlayEntry;
  VideoChatMessageController? videoChatMessageController;

  @override
  void initState() {
    super.initState();
    videoConferenceRenderPool.addListener(_update);
    //优先展示当前活动的会议，其次是有当前视频邀请消息的会议，最后是准备创建的会议
    videoChatMessageController =
        videoConferenceRenderPool.videoChatMessageController;
    //当前无激活的会议，创建基于当前聊天的视频消息控制器
    if (videoChatMessageController == null) {
      ChatSummary? chatSummary = chatMessageController.chatSummary;
      ChatMessage? chatMessage = chatMessageController.current;
      if (chatMessage != null &&
          chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        videoChatMessageController = videoConferenceRenderPool
            .getVideoChatMessageController(chatMessage.messageId!);
      }
      if (videoChatMessageController == null) {
        videoChatMessageController = VideoChatMessageController();
        videoChatMessageController!.setChatSummary(chatSummary);
      }
    }
  }

  _update() {}

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      indexWidgetProvider.push('video_chat');
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(builder: (context) {
      return Align(
        alignment: Alignment.topRight,
        child: WidgetUtil.buildCircleButton(
            padding: const EdgeInsets.all(15.0),
            backgroundColor: myself.primary,
            onPressed: () {
              _closeOverlayEntry();
            },
            child:
                const Icon(size: 32, color: Colors.white, Icons.zoom_out_map)),
      );
    });
    Overlay.of(context)!.insert(overlayEntry!);
    indexWidgetProvider.pop();
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Swiper(
      controller: SwiperController(),
      itemCount: 2,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        Widget view = LocalVideoWidget(
            videoChatMessageController: videoChatMessageController!);
        if (index == 1) {
          view = Container();
          view = RemoteVideoWidget(
              videoChatMessageController: videoChatMessageController!);
        }
        return Center(child: view);
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
    Widget videoChatView = Container();
    var name = '';
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      name = chatSummary.name!;
      videoChatView = _buildVideoChatView(context);
    }
    return AppBarView(
      title: '${AppLocalizations.t(widget.title)}  $name',
      withLeading: true,
      rightWidgets: rightWidgets,
      child: videoChatView,
    );
  }

  @override
  void dispose() {
    videoConferenceRenderPool.removeListener(_update);
    super.dispose();
  }
}
