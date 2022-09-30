import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/audio/blue_fire_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/just_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_widget.dart';
import 'package:flutter/material.dart';

///平台标准的audio-player的实现，
class PlatformAudioPlayer extends StatefulWidget {
  late final AbstractMediaPlayerController controller;

  PlatformAudioPlayer({Key? key, AbstractMediaPlayerController? controller})
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller is JustAudioPlayerController) {
      var player = JustAudioPlayer(
          controller: widget.controller as JustAudioPlayerController);
      return player;
    } else {
      var player = PlatformMediaPlayer.buildMediaPlayer(
          context, widget.controller);
      return player;
    }
  }
}
