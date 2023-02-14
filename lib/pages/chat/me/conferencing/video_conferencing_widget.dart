import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/pages/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/video/remote_video_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///视频会议通话窗口，分页显示本地视频和远程视频
class VideoConferencingWidget extends StatefulWidget with TileDataMixin {
  const VideoConferencingWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoConferencingWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_conferencing';

  @override
  IconData get iconData => Icons.video_camera_back;

  @override
  String get title => 'VideoConferencing';
}

class _VideoConferencingWidgetState extends State<VideoConferencingWidget> {
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    videoRoomRenderPool.addListener(_update);
  }

  _update() {}

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      indexWidgetProvider.push('video_conferencing');
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
    var roomId = videoRoomRenderPool.roomId;
    return Swiper(
      controller: SwiperController(),
      itemCount: 2,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        Widget view = LocalVideoWidget(key: UniqueKey());
        if (index == 1) {
          view = Container();
          if (roomId != null) {
            view = RemoteVideoWidget(
              key: UniqueKey(),
              videoMode: VideoMode.conferencing,
            );
          }
        }
        return Center(child: view);
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
    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: _buildVideoChatView(context),
    );
  }

  @override
  void dispose() {
    videoRoomRenderPool.removeListener(_update);
    super.dispose();
  }
}
