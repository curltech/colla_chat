import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///平台标准的video_player的实现，移动采用flick，桌面采用vlc
class PlatformVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  PlatformVideoPlayerWidget({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => _PlatformVideoPlayerWidgetState();

  @override
  String get routeName => 'video_player';

  @override
  Icon get icon => const Icon(Icons.videocam);

  @override
  String get title => 'VideoPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformVideoPlayerWidgetState extends State<PlatformVideoPlayerWidget> {
  MediaPlayerType? mediaPlayerType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<AppBarPopupMenu>? _buildRightPopupMenus() {
    List<AppBarPopupMenu> menus = [];
    for (var type in MediaPlayerType.values) {
      AppBarPopupMenu menu = AppBarPopupMenu(
          title: type.name,
          onPressed: () {
            setState(() {
              mediaPlayerType = type;
              logger.i('mediaPlayerType:$type');
            });
          });
      menus.add(menu);
    }
    return menus;
  }

  @override
  Widget build(BuildContext context) {
    //String filename = 'C:\\Users\\hujs\\AppData\\Local\\Temp\\1d819cab.m4a';
    return AppBarView(
      title: Text(AppLocalizations.t('VideoPlayer')),
      withLeading: true,
      rightPopupMenus: _buildRightPopupMenus(),
      child: mediaPlayerType != null
          ? PlatformMediaPlayer(
              showControls: false,
              showVolume: true,
              showSpeed: true,
              showPlaylist: true,
              showMediaView: true,
              mediaPlayerType: mediaPlayerType!,
            )
          : const Center(child: Text('Please select a MediaPlayerType!')),
    );
  }
}
