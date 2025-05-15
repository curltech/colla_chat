import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';
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
  final Color? color;
  final double? height;
  final double? width;
  final List<int>? data;
  final AbstractMediaPlayerController mediaPlayerController;
  final ValueNotifier<int> index = ValueNotifier<int>(0);
  late final Widget player;

  PlatformMediaPlayer({
    super.key,
    required this.mediaPlayerController,
    this.showClosedCaptionButton = true,
    this.showFullscreenButton = true,
    this.showVolumeButton = true,
    this.showSpeedButton = false,
    this.color,
    this.width,
    this.height,
    this.data,
  }) {
    if (platformParams.windows) {
      WindowsVideoPlayer.registerWith();
    }
    player = _buildMediaPlayer();
  }

  Widget _buildMediaPlayer() {
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

    return Container(
      margin: const EdgeInsets.all(0.0),
      width: width,
      height: height,
      decoration: BoxDecoration(color: color),
      child: Center(
        child: player,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return player;
  }
}
