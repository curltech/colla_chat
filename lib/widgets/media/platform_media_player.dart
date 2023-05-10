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
  SwiperController? swiperController;
  late AbstractMediaPlayerController controller;

  PlatformMediaPlayer(
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
      this.data,
      this.swiperController})
      : super(key: key) {
    swiperController ??= SwiperController();
    _updateMediaPlayerType();
  }

  _updateMediaPlayerType() {
    if (videoPlayerType != null) {
      switch (videoPlayerType) {
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
          controller = WebViewVideoPlayerController();
          break;
      }
    } else if (audioPlayerType != null) {
      switch (audioPlayerType) {
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
          controller = WebViewVideoPlayerController();
          break;
      }
    } else {
      controller = WebViewVideoPlayerController();
    }
    if (filename != null) {
      controller.add(filename: filename!);
      controller.playlistVisible = false;
    }
  }

  _onSelected(int index, String filename) {
    swiperController!.move(1);
  }

  @override
  State createState() => _PlatformMediaPlayerState();
}

class _PlatformMediaPlayerState extends State<PlatformMediaPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget mediaView;
    Widget player = widget.controller.buildMediaPlayer(key: UniqueKey());
    if (widget.showPlaylist) {
      mediaView = Swiper(
        itemCount: 2,
        controller: widget.swiperController!,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return PlaylistWidget(
              controller: widget.controller,
              onSelected: widget._onSelected,
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
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
