import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:universal_html/html.dart' as html;
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flick_video_player/src/utils/web_key_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

///基于Chewie实现的媒体播放器和记录器，
class ChewieVideoPlayerController extends OriginVideoPlayerController {
  ChewieVideoPlayerController();

  Future<ChewieController?> _getChewieController() async {
    var controller = await this.controller;
    if (controller == null) {
      return null;
    }
    ChewieController chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: true,
      progressIndicatorDelay: const Duration(milliseconds: 200),
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: () {},
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      hideControlsTimer: const Duration(seconds: 3),
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightGreen,
      ),
      placeholder: Container(
        color: Colors.grey,
      ),
      autoInitialize: true,
    );

    return chewieController;
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    Widget player = FutureBuilder<ChewieController?>(
        future: _getChewieController(),
        builder:
            (BuildContext context, AsyncSnapshot<ChewieController?> snapshot) {
          if (snapshot.hasData) {
            ChewieController? chewieController = snapshot.data;
            if (chewieController != null) {
              return Chewie(
                key: key,
                controller: chewieController,
              );
            }
          }
          return const Center(child: Text('Please select a media file!'));
        });

    return player;
  }
}
