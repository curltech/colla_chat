import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 平台的单个音频媒体播放器组件
class PlatformAudioPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  final bool showPlaylist;
  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    onSelected: _onSelected,
    playlistController: playlistController,
  );
  late final AbstractMediaPlayerController mediaPlayerController =
      BlueFireAudioPlayerController(playlistController);
  final AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;
  final RxInt index = 0.obs;

  PlatformAudioPlayer({
    super.key,
    this.showPlaylist = true,
    List<String>? filenames,
  }) {
    if (filenames != null) {
      playlistController.addMediaFiles(filenames: filenames);
    }
  }

  Widget _buildAudioPlayer(BuildContext context) {
    Widget mediaView = Swiper(
      itemCount: 2,
      index: index.value,
      controller: swiperController,
      onIndexChanged: (int index) {
        this.index.value = index;
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return playlistWidget;
        }
        if (index == 1) {
          return Center(child: mediaPlayerController.buildMediaPlayer());
        }
        return nilBox;
      },
    );

    return Center(
      child: mediaView,
    );
  }

  _onSelected(int index, String filename) {
    // swiperController.move(1);
  }

  @override
  Widget build(BuildContext context) {
    return _buildAudioPlayer(context);
  }
}
