import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

class PlatformAudioPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  final PlaylistController playlistController = PlaylistController();
  late final PlaylistMediaPlayer playlistMediaPlayer;
  final AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;
  late final AbstractMediaPlayerController mediaPlayerController;

  PlatformAudioPlayer({
    super.key,
    List<String>? filenames,
  }) {
    if (filenames != null) {
      playlistController.addMediaFiles(filenames: filenames);
    }
    mediaPlayerController = BlueFireAudioPlayerController(playlistController);
    playlistMediaPlayer = PlaylistMediaPlayer(
      key: UniqueKey(),
      playlistController: playlistController, player: mediaPlayerController.buildMediaPlayer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return playlistMediaPlayer;
  }
}
