import 'package:chewie/chewie.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:flutter/material.dart';

///基于Chewie实现的媒体播放器和记录器，
class ChewieVideoPlayerController extends OriginVideoPlayerController {
  ChewieController? chewieController;

  ChewieVideoPlayerController(super.playlistController);

  void _buildChewieController() {
    var controller = videoPlayerController;
    if (controller == null) {
      chewieController = null;
      return;
    }
    chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: autoPlay,
        looping: true,
        progressIndicatorDelay: const Duration(milliseconds: 200),
        additionalOptions: (context) {
          return <OptionItem>[
            OptionItem(
              onTap: (BuildContext context) {},
              iconData: Icons.live_tv_sharp,
              title: 'Toggle Video Src',
            ),
          ];
        },
        hideControlsTimer: const Duration(seconds: 3),
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: myself.primary,
          handleColor: myself.primary,
          backgroundColor: myself.secondary,
          bufferedColor: Colors.green,
        ),
        placeholder: Container(
          color: Colors.black,
        ),
        autoInitialize: true,);
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    key ??= this.key;
    Widget player = ValueListenableBuilder(
        valueListenable: filename,
        builder: (BuildContext context, String? filename, Widget? child) {
          if (videoPlayerController != null) {
            _buildChewieController();
            if (chewieController != null) {
              return Stack(children: [
                Chewie(
                  key: key,
                  controller: chewieController!,
                ),
                buildPlaylistController()
              ]);
            }
          }
          return Center(child: buildOpenFileWidget());
        });

    return player;
  }

  @override
  void close() {
    super.close();
    if (chewieController != null) {
      chewieController!.dispose();
      chewieController = null;
    }
  }
}
