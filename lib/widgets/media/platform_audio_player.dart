import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 平台的单个音频媒体播放器组件
class PlatformAudioPlayer extends StatelessWidget {
  final PlaylistController playlistController;
  late final AbstractMediaPlayerController mediaPlayerController =
      BlueFireAudioPlayerController(playlistController);

  PlatformAudioPlayer({
    super.key,
    required this.playlistController,
  });

  Widget _buildAudioPlayer(BuildContext context) {
    Widget mediaView = Center(child: mediaPlayerController.buildMediaPlayer());

    return mediaView;
  }

  @override
  Widget build(BuildContext context) {
    return _buildAudioPlayer(context);
  }
}
