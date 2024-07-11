import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

class PlatformAudioPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  PlaylistController? playlistController;
  List<String>? filenames;
  late final PlatformMediaPlayer platformMediaPlayer;
  AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;
  late AbstractMediaPlayerController mediaPlayerController;

  PlatformAudioPlayer({
    super.key,
    this.filenames,
    this.playlistController,
  }) {
    playlistController ??= PlaylistController();
    if (filenames != null) {
      playlistController!.addMediaFiles(filenames: filenames!);
    }
    mediaPlayerController = BlueFireAudioPlayerController(playlistController!);
    platformMediaPlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: true,
      mediaPlayerController: mediaPlayerController,
      swiperController: swiperController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return platformMediaPlayer;
  }
}
