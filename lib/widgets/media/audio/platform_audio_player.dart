import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/audio/blue_fire_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/just_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///平台标准的audio-player的实现，
class PlatformAudioPlayer extends StatefulWidget {
  late final AbstractMediaPlayerController controller;

  //自定义简单控制器模式
  final bool simple;

  //是否显示播放列表
  final bool showPlayerList;

  PlatformAudioPlayer(
      {Key? key,
      AbstractMediaPlayerController? controller,
      this.simple = false,
      this.showPlayerList = true})
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
          simple: widget.simple,
          showPlayerList: widget.showPlayerList);
      return player;
    } else {
      var player = PlatformMediaPlayer(
          controller: widget.controller,
          showControls: false,
          simple: widget.simple,
          showPlayerList: widget.showPlayerList);
      return player;
    }
  }
}
