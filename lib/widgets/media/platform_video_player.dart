import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';

class PlatformVideoPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  late final AbstractMediaPlayerController mediaPlayerController;
  bool showPlaylist;
  List<String>? filenames;
  PlaylistController? playlistController;
  late final PlatformMediaPlayer platformMediaPlayer;

  PlatformVideoPlayer({
    super.key,
    this.filenames,
    this.showPlaylist = true,
    this.playlistController,
  }) {
    if (platformParams.windows) {
      WindowsVideoPlayer.registerWith();
    }
    playlistController ??= PlaylistController();
    if (filenames != null) {
      playlistController!.addMediaFiles(filenames: filenames!);
    }
    mediaPlayerController = MediaKitVideoPlayerController(playlistController!);
    platformMediaPlayer = PlatformMediaPlayer(
      showPlaylist: showPlaylist,
      mediaPlayerController: mediaPlayerController,
      swiperController: swiperController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return platformMediaPlayer;
  }
}
