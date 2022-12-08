import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';

///基于flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends OriginVideoPlayerController {
  FlickVideoPlayerController();

  Future<FlickManager?> _getFlickManager() async {
    var controller = await this.controller;
    if (controller == null) {
      return null;
    }
    FlickManager flickManager = FlickManager(
      videoPlayerController: controller,
      onVideoEnd: next,
    );

    return flickManager;
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    Widget flickVideoWithControls = const FlickVideoWithControls(
        videoFit: BoxFit.cover, controls: FlickPortraitControls());

    Widget player = FutureBuilder<FlickManager?>(
        future: _getFlickManager(),
        builder: (BuildContext context, AsyncSnapshot<FlickManager?> snapshot) {
          if (snapshot.hasData) {
            FlickManager? flickManager = snapshot.data;
            if (flickManager != null) {
              return FlickVideoPlayer(
                key: key,
                flickManager: flickManager!,
                flickVideoWithControls: flickVideoWithControls,
              );
            }
          }
          return const Center(child: Text('Please select a media file!'));
        });

    return player;
  }
}
