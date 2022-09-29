import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/audio/blue_fire_audio_player_controller.dart';
import 'package:colla_chat/widgets/audio/just_audio_player.dart';
import 'package:colla_chat/widgets/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/platform_media_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class Vlc1MediaSource {
  static Future<String> media({String? filename, Uint8List? data}) async {
    if (filename == null) {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
    }

    return Future.value(filename);
  }

  static Future<List<String>> playlist(List<String> filenames) async {
    List<String> playlist = [];
    for (var filename in filenames) {
      playlist.add(await media(filename: filename));
    }

    return playlist;
  }
}



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
      this.controller = JustAudioPlayerController();
    } else {
      this.controller = BlueFireAudioPlayerController();
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
      var player = BlueFireAudioPlayer(
        controller: widget.controller as BlueFireAudioPlayerController,
      );
      return player;
    }
  }
}
