import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///平台标准的AudioPlayer的实现，支持标准的audioplayers，just_audio和webview
class PlatformAudioPlayerWidget extends StatefulWidget with TileDataMixin {
  const PlatformAudioPlayerWidget({super.key});

  @override
  State createState() => _PlatformAudioPlayerWidgetState();

  @override
  String get routeName => 'audio_player';

  @override
  IconData get iconData => Icons.audiotrack;

  @override
  String get title => 'AudioPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformAudioPlayerWidgetState extends State<PlatformAudioPlayerWidget> {
  AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;

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
    for (var type in AudioPlayerType.values) {
      AppBarPopupMenu menu = AppBarPopupMenu(
          title: type.name,
          onPressed: () {
            setState(() {
              audioPlayerType = type;
            });
          });
      menus.add(menu);
    }
    return menus;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightPopupMenus: _buildRightPopupMenus(),
      child: PlatformMediaPlayer(
          key: UniqueKey(),
          showPlaylist: true,
          audioPlayerType: audioPlayerType),
    );
  }
}
