import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/remote_video_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///视频通话窗口，分页显示本地视频和远程视频
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
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'VideoChat';
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    videoRoomPool.addListener(_update);
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
            backgroundColor: appDataProvider.themeData.colorScheme.primary,
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
    var roomId = videoRoomPool.roomId;
    return Swiper(
      controller: SwiperController(),
      itemCount: 2,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        Widget view = const LocalVideoWidget();
        if (index == 1) {
          view = Container();
          if (roomId != null) {
            view = RemoteVideoWidget(roomId: roomId);
          }
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
    List<Widget> rightWidgets = [
      IconButton(
          onPressed: () {
            _minimize(context);
          },
          icon: const Icon(Icons.zoom_in_map)),
    ];
    return AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: true,
      rightWidgets: rightWidgets,
      child: _buildVideoChatView(context),
    );
  }

  @override
  void dispose() {
    videoRoomPool.removeListener(_update);
    super.dispose();
  }
}
