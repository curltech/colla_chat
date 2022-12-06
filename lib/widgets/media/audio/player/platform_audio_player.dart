import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player_controller.dart';

import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/just_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///平台标准的audio-player的实现，
class PlatformAudioPlayer extends StatefulWidget {
  late final AbstractMediaPlayerController controller;

  //自定义简单控制器模式
  final bool showVolume;
  final bool showSpeed;

  //是否显示播放列表
  final bool showPlaylist;
  final bool showMediaView;
  final String? filename;
  final List<int>? data;

  PlatformAudioPlayer(
      {Key? key,
      AbstractMediaPlayerController? controller,
      this.showVolume = true,
      this.showSpeed = false,
      this.showPlaylist = true,
      this.showMediaView = false,
      this.filename,
      this.data})
      : super(key: key) {
    if (platformParams.ios ||
        platformParams.android ||
        platformParams.web ||
        platformParams.windows ||
        platformParams.macos ||
        platformParams.linux) {
      this.controller = BlueFireAudioPlayerController();
    } else {
      this.controller = JustAudioPlayerController();
    }
  }

  @override
  State createState() => _PlatformAudioPlayerState();
}

class _PlatformAudioPlayerState extends State<PlatformAudioPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    if (widget.filename != null || widget.data != null) {
      widget.controller.add(filename: widget.filename, data: widget.data);
    }
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller is JustAudioPlayerController) {
      var player = JustAudioPlayer(
        controller: widget.controller as JustAudioPlayerController,
        showVolume: widget.showVolume,
        showSpeed: widget.showSpeed,
        showPlaylist: widget.showPlaylist,
        showMediaView: widget.showMediaView,
        filename: widget.filename,
        data: widget.data,
      );
      return player;
    } else {
      var player = PlatformMediaPlayer(
        mediaPlayerType: MediaPlayerType.bluefire,
        showControls: false,
        showVolume: widget.showVolume,
        showSpeed: widget.showSpeed,
        showPlaylist: widget.showPlaylist,
        showMediaView: widget.showMediaView,
        filename: widget.filename,
        data: widget.data,
      );
      return player;
    }
  }
}
