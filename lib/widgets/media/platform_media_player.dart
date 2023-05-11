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
  final bool showClosedCaptionButton;
  final bool showFullscreenButton;
  final bool showVolumeButton;
  final bool showSpeedButton;
  final bool showPlaylist;
  final Color? color;
  final double? height;
  final double? width;

  final List<String>? filenames;
  final List<int>? data;
  final SwiperController swiperController;
  AbstractMediaPlayerController mediaPlayerController;
  VideoPlayerType? videoPlayerType;
  AudioPlayerType? audioPlayerType;

  PlatformMediaPlayer({
    Key? key,
    this.videoPlayerType,
    this.audioPlayerType,
    required this.mediaPlayerController,
    required this.swiperController,
    this.showClosedCaptionButton = true,
    this.showFullscreenButton = true,
    this.showVolumeButton = true,
    this.showSpeedButton = false,
    this.showPlaylist = true,
    this.color,
    this.width,
    this.height,
    this.filenames,
    this.data,
  }) : super(key: key);

  _updateMediaPlayerType() {
    if (videoPlayerType != null) {
      switch (videoPlayerType) {
        case VideoPlayerType.dart_vlc:
          //controller = DartVlcVideoPlayerController();
          break;
        case VideoPlayerType.flick:
          mediaPlayerController = FlickVideoPlayerController();
          break;
        case VideoPlayerType.origin:
          mediaPlayerController = OriginVideoPlayerController();
          break;
        case VideoPlayerType.chewie:
          mediaPlayerController = ChewieVideoPlayerController();
          break;
        case VideoPlayerType.webview:
          mediaPlayerController = WebViewVideoPlayerController();
          break;
        default:
          mediaPlayerController = WebViewVideoPlayerController();
          break;
      }
    } else if (audioPlayerType != null) {
      switch (audioPlayerType) {
        case AudioPlayerType.webview:
          mediaPlayerController = WebViewVideoPlayerController();
          break;
        case AudioPlayerType.just:
          mediaPlayerController = JustAudioPlayerController();
          break;
        case AudioPlayerType.audioplayers:
          mediaPlayerController = BlueFireAudioPlayerController();
          break;
        case AudioPlayerType.waveforms:
          mediaPlayerController = WaveformsAudioPlayerController();
          break;
        default:
          mediaPlayerController = WebViewVideoPlayerController();
          break;
      }
    } else {
      videoPlayerType = VideoPlayerType.webview;
      mediaPlayerController = WebViewVideoPlayerController();
    }
    if (filenames != null) {
      mediaPlayerController.addAll(filenames: filenames!);
    }
  }

  _onSelected(int index, String filename) {
    swiperController.move(1);
  }

  @override
  State createState() => _PlatformMediaPlayerState();
}

class _PlatformMediaPlayerState extends State<PlatformMediaPlayer> {
  @override
  void initState() {
    super.initState();
    widget.mediaPlayerController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget mediaView;
    Widget player =
        widget.mediaPlayerController.buildMediaPlayer(key: UniqueKey());
    int index = widget.swiperController.index;
    if (widget.mediaPlayerController.currentIndex == -1) {
      index = 0;
    }
    if (widget.showPlaylist) {
      mediaView = Swiper(
        itemCount: 2,
        index: index,
        controller: widget.swiperController,
        onIndexChanged: (int index) {
          widget.swiperController.index = index;
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return PlaylistWidget(
              mediaPlayerController: widget.mediaPlayerController,
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
    widget.mediaPlayerController.removeListener(_update);
    super.dispose();
  }
}
