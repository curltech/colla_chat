import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/remote_video_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';

///视频通话窗口，分页显示本地视频和远程视频
class VideoChatWidget extends StatefulWidget {
  const VideoChatWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoChatWidgetState();
  }
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
  }

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      chatMessageController.chatView = ChatView.video;
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(builder: (context) {
      return Align(
        alignment: Alignment.topRight,
        child: WidgetUtil.buildCircleButton(
            padding: const EdgeInsets.all(15.0),
            backgroundColor: appDataProvider.themeData.colorScheme.primary,
            onPressed: () {
              _closeOverlayEntry();
            },
            child:
                const Icon(size: 32, color: Colors.white, Icons.zoom_out_map)),
      );
    });
    Overlay.of(context)!.insert(overlayEntry!);
    chatMessageController.chatView = ChatView.text;
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Swiper(
      controller: SwiperController(),
      itemCount: 2,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        Widget view = const LocalVideoWidget();
        if (index == 1) {
          view = const RemoteVideoWidget();
        }
        return Center(child: view);
      },
      // pagination: SwiperPagination(
      //     builder: DotSwiperPaginationBuilder(
      //   activeColor: appDataProvider.themeData.colorScheme.primary,
      //   color: Colors.white,
      //   activeSize: 15,)
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoChatView(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
