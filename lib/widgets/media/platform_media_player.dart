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
class PlatformMediaPlayer extends StatefulWidget {
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
  void Function(int)? onIndexChanged;

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
    this.onIndexChanged,
  });

  _onSelected(int index, String filename) {
    swiperController!.move(1);
  }

  @override
  State createState() => _PlatformMediaPlayerState();
}

class _PlatformMediaPlayerState extends State<PlatformMediaPlayer> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    widget.mediaPlayerController.addListener(_update);
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget player = widget.mediaPlayerController.buildMediaPlayer();
    player = VisibilityDetector(
      key: ObjectKey(player),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          widget.mediaPlayerController.pause();
        } else if (info.visibleFraction == 1) {
          widget.mediaPlayerController.resume();
        }
      },
      child: player,
    );

    Widget mediaView;
    if (widget.showPlaylist && widget.swiperController != null) {
      mediaView = Swiper(
        itemCount: 2,
        index: index,
        controller: widget.swiperController,
        onIndexChanged: (int index) {
          this.index = index;
          if (widget.onIndexChanged != null) {
            widget.onIndexChanged!(index);
          }
          if (index == 1) {
            widget.mediaPlayerController.play();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return PlaylistWidget(
              onSelected: widget._onSelected,
              playlistController:
                  widget.mediaPlayerController.playlistController,
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
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(color: widget.color),
      child: Center(
        child: mediaView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPlayer(context);
  }

  @override
  void dispose() {
    widget.mediaPlayerController.removeListener(_update);
    super.dispose();
  }
}
