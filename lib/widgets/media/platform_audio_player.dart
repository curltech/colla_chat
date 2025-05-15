import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

/// 平台的单个音频媒体播放器组件
class PlatformAudioPlayer extends StatelessWidget {
  final PlaylistController playlistController = PlaylistController();
  late final AbstractMediaPlayerController mediaPlayerController =
      BlueFireAudioPlayerController(playlistController);
  late final PlaylistMediaPlayer playlistMediaPlayer;
  final AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;

  PlatformAudioPlayer({
    super.key,
    List<String>? filenames,
  }) {
    if (filenames != null) {
      playlistController.addMediaFiles(filenames: filenames);
    }
    playlistMediaPlayer = PlaylistMediaPlayer(
      key: UniqueKey(),
      playlistController: playlistController,
      player: mediaPlayerController.buildMediaPlayer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return playlistMediaPlayer;
  }
}
