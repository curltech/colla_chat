import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum VideoPlayerType {
  dart_vlc,
  flick,
  chewie,
  origin,
  webview,
}

enum AudioPlayerType {
  webview,
  just,
  audioplayers,
  waveforms,
}

///平台的媒体播放器组件
class PlatformMediaPlayer extends StatelessWidget {
  final bool showClosedCaptionButton;
  final bool showFullscreenButton;
  final bool showVolumeButton;
  final bool showSpeedButton;
  final bool showPlaylist;
  final Color? color;
  final double? height;
  final double? width;
  final List<int>? data;
  final SwiperController? swiperController;
  AbstractMediaPlayerController mediaPlayerController;
  final ValueNotifier<int> index = ValueNotifier<int>(0);

  PlatformMediaPlayer({
    super.key,
    required this.mediaPlayerController,
    this.swiperController,
    this.showClosedCaptionButton = true,
    this.showFullscreenButton = true,
    this.showVolumeButton = true,
    this.showSpeedButton = false,
    this.showPlaylist = true,
    this.color,
    this.width,
    this.height,
    this.data,
  });

  _onSelected(int index, String filename) {
    swiperController!.move(1);
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget player = mediaPlayerController.buildMediaPlayer();
    player = VisibilityDetector(
      key: ObjectKey(player),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          mediaPlayerController.pause();
        } else if (info.visibleFraction == 1) {
          mediaPlayerController.resume();
        }
      },
      child: player,
    );

    Widget mediaView;
    if (showPlaylist && swiperController != null) {
      mediaView = Swiper(
        itemCount: 2,
        index: index.value,
        controller: swiperController,
        onIndexChanged: (int index) {
          this.index.value = index;
          if (index == 1) {
            mediaPlayerController.play();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return PlaylistWidget(
              onSelected: _onSelected,
              playlistController: mediaPlayerController.playlistController,
            );
          }
          if (index == 1) {
            return player;
          }
          return Container();
        },
      );
    } else {
      mediaView = player;
    }
    return Container(
      margin: const EdgeInsets.all(0.0),
      width: width,
      height: height,
      decoration: BoxDecoration(color: color),
      child: Center(
        child: mediaView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPlayer(context);
  }
}
