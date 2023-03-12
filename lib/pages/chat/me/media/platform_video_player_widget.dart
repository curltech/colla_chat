import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';

///平台标准的video_player的实现，缺省采用origin
class PlatformVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  PlatformVideoPlayerWidget({
    Key? key,
  }) : super(key: key) {
    if (platformParams.windows) {
      WindowsVideoPlayer.registerWith();
    }
  }

  @override
  State createState() => _PlatformVideoPlayerWidgetState();

  @override
  String get routeName => 'video_player';

  @override
  IconData get iconData => Icons.videocam;

  @override
  String get title => 'VideoPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformVideoPlayerWidgetState extends State<PlatformVideoPlayerWidget> {
  VideoPlayerType videoPlayerType = VideoPlayerType.origin;

  @override
  void initState() {
    super.initState();
  }

  List<AppBarPopupMenu>? _buildRightPopupMenus() {
    List<AppBarPopupMenu> menus = [];
    for (var type in VideoPlayerType.values) {
      AppBarPopupMenu menu = AppBarPopupMenu(
          title: type.name,
          onPressed: () {
            setState(() {
              videoPlayerType = type;
            });
          });
      menus.add(menu);
    }
    return menus;
  }

  @override
  Widget build(BuildContext context) {
    List<AppBarPopupMenu>? rightPopupMenus = _buildRightPopupMenus();
    Widget child = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: true,
      videoPlayerType: videoPlayerType,
    );
    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightPopupMenus: rightPopupMenus,
      child: child,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
