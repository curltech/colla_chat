import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';

///基于Flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends OriginVideoPlayerController {
  FlickManager? flickManager;

  FlickVideoPlayerController(super.playlistController);

  void _buildFlickManager() {
    var controller = videoPlayerController;
    if (controller == null) {
      flickManager = null;
      return;
    }
    flickManager = FlickManager(
      videoPlayerController: controller,
      autoPlay: true,
      autoInitialize: true,
    );
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    Widget player = ValueListenableBuilder(
        valueListenable: filename,
        builder: (BuildContext context, String? filename, Widget? child) {
          if (videoPlayerController != null) {
            _buildFlickManager();
            if (flickManager != null) {
              Widget flickVideoPlayer = FlickVideoPlayer(
                key: key,
                flickManager: flickManager!,
                flickVideoWithControls: FlickVideoWithControls(
                  videoFit: BoxFit.contain,
                  controls: FlickPortraitControls(
                    progressBarSettings: FlickProgressBarSettings(
                        playedColor: myself.primary,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white),
                  ),
                ),
                flickVideoWithControlsFullscreen: const FlickVideoWithControls(
                  videoFit: BoxFit.contain,
                  controls: FlickLandscapeControls(),
                ),
              );
              return Stack(
                children: [
                  flickVideoPlayer,
                  buildPlaylistController(),
                ],
              );
            }
          }
          if (playlistController.current != null) {
            return LoadingUtil.buildLoadingIndicator();
          }
          return Center(
              child: CommonAutoSizeText(
            AppLocalizations.t('Please select a media file'),
            style: const TextStyle(color: Colors.white),
          ));
        });

    return player;
  }

  @override
  void close() {
    super.close();
    if (flickManager != null) {
      flickManager!.dispose();
      flickManager = null;
    }
  }
}
