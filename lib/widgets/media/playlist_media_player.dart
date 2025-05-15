import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 带有播放列表平台的媒体播放器组件
class PlaylistMediaPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();

  final Widget player;
  final PlaylistController playlistController;
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    onSelected: _onSelected,
    playlistController: playlistController,
  );
  final RxInt index = 0.obs;

  PlaylistMediaPlayer(
      {super.key, required this.player, required this.playlistController});

  _onSelected(int index, String filename) {
    // swiperController.move(1);
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget mediaView = Swiper(
      itemCount: 2,
      index: index.value,
      controller: swiperController,
      onIndexChanged: (int index) {
        this.index.value = index;
        if (index == 1) {
          (player as PlatformMediaPlayer).mediaPlayerController.play();
        }
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return playlistWidget;
        }
        if (index == 1) {
          return player;
        }
        return nilBox;
      },
    );

    return Center(
      child: mediaView,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPlayer(context);
  }
}
