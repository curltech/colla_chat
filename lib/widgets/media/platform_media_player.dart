import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/just_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/waveforms_audio_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/chewie_video_player.dart';
import 'package:colla_chat/widgets/media/video/flick_video_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:colla_chat/widgets/media/video/webview_video_player.dart';
import 'package:flutter/material.dart';

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
  final VideoPlayerType? videoPlayerType;
  final AudioPlayerType? audioPlayerType;
  final bool showClosedCaptionButton;
  final bool showFullscreenButton;
  final bool showVolumeButton;
  final bool showSpeedButton;
  final bool showPlaylist;
  final Color? color;
  final double? height;
  final double? width;

  final String? filename;
  final List<int>? data;

  const PlatformMediaPlayer(
      {Key? key,
      this.videoPlayerType,
      this.audioPlayerType,
      this.showClosedCaptionButton = true,
      this.showFullscreenButton = true,
      this.showVolumeButton = true,
      this.showSpeedButton = false,
      this.showPlaylist = true,
      this.color,
      this.width,
      this.height,
      this.filename,
      this.data})
      : super(key: key);

  @override
  State createState() => _PlatformMediaPlayerState();
}

class _PlatformMediaPlayerState extends State<PlatformMediaPlayer> {
  late AbstractMediaPlayerController controller;
  SwiperController swiperController = SwiperController();

  @override
  void initState() {
    super.initState();
    _updateMediaPlayerType();
    controller.addListener(_update);
    if (widget.filename != null) {
      controller.add(filename: widget.filename!);
      controller.playlistVisible = false;
    }
  }

  _update() {
    setState(() {});
  }

  _updateMediaPlayerType() {
    switch (widget.videoPlayerType) {
      case VideoPlayerType.dart_vlc:
        //controller = DartVlcVideoPlayerController();
        break;
      case VideoPlayerType.flick:
        controller = FlickVideoPlayerController();
        break;
      case VideoPlayerType.origin:
        controller = OriginVideoPlayerController();
        break;
      case VideoPlayerType.chewie:
        controller = ChewieVideoPlayerController();
        break;
      case VideoPlayerType.webview:
        controller = WebViewVideoPlayerController();
        break;
      default:
        break;
    }
    switch (widget.audioPlayerType) {
      case AudioPlayerType.webview:
        controller = WebViewVideoPlayerController();
        break;
      case AudioPlayerType.just:
        controller = JustAudioPlayerController();
        break;
      case AudioPlayerType.audioplayers:
        controller = BlueFireAudioPlayerController();
        break;
      case AudioPlayerType.waveforms:
        controller = WaveformsAudioPlayerController();
        break;
      default:
        break;
    }
  }

  _onSelected(int index, String filename) {
    swiperController.move(1);
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget mediaView;
    Widget player = controller.buildMediaPlayer(key: UniqueKey());
    if (widget.showPlaylist) {
      mediaView = Swiper(
        itemCount: 2,
        controller: swiperController,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return PlaylistWidget(
              controller: controller,
              onSelected: _onSelected,
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
    controller.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}
