import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/just_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/waveforms_audio_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/chewie_video_player.dart';
import 'package:colla_chat/widgets/media/video/dart_vlc_video_player.dart';
import 'package:colla_chat/widgets/media/video/flick_video_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:colla_chat/widgets/media/video/webview_video_player.dart';
import 'package:flutter/material.dart';

enum MediaPlayerType {
  dart_vlc,
  flick,
  chewie,
  origin,
  webview,
  just,
  audioplayers,
  waveforms,
}

///平台的媒体播放器组件

class PlatformMediaPlayer extends StatefulWidget {
  final MediaPlayerType mediaPlayerType;
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
      required this.mediaPlayerType,
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

  @override
  void initState() {
    super.initState();
    _updateMediaPlayerType();
    if (widget.filename != null || widget.data != null) {
      controller
          .add(filename: widget.filename, data: widget.data)
          .then((value) {
        setState(() {});
      });
    }
  }

  _updateMediaPlayerType() {
    switch (widget.mediaPlayerType) {
      case MediaPlayerType.dart_vlc:
        controller = DartVlcVideoPlayerController();
        break;
      case MediaPlayerType.flick:
        controller = FlickVideoPlayerController();
        break;
      case MediaPlayerType.origin:
        controller = OriginVideoPlayerController();
        break;
      case MediaPlayerType.chewie:
        controller = ChewieVideoPlayerController();
        break;
      case MediaPlayerType.webview:
        controller = WebViewVideoPlayerController();
        break;
      case MediaPlayerType.just:
        controller = JustAudioPlayerController();
        break;
      case MediaPlayerType.audioplayers:
        controller = BlueFireAudioPlayerController();
        break;
      case MediaPlayerType.waveforms:
        controller = WaveformsAudioPlayerController();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPlayer(context);
  }

  Widget _buildMediaPlayer(BuildContext context) {
    Widget playlistWidget = Visibility(
        visible: controller.playlistVisible,
        child: PlaylistWidget(controller: controller));

    Widget playlistButton = InkWell(
      child: controller.playlistVisible
          ? const Icon(Icons.playlist_remove, size: 24)
          : const Icon(Icons.playlist_add_check, size: 24),
      onTap: () {
        controller.playlistVisible = !controller.playlistVisible;
      },
    );

    // Widget player = Visibility(
    //     visible: !controller.playlistVisible,
    //     child: controller.buildMediaPlayer(key: UniqueKey()));

    Widget player = controller.buildMediaPlayer(key: UniqueKey());

    Widget mediaView = Stack(children: [player]);

    Color color = widget.color ?? Colors.black.withOpacity(1);
    return Container(
      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(color: color),
      child: Center(
        child: mediaView,
      ),
    );
  }
}
