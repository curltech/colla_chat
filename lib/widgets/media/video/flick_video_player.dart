import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

///基于Flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends OriginVideoPlayerController {
  FlickManager? flickManager;

  FlickVideoPlayerController();

  void _buildFlickManager() {
    var controller = videoPlayerController.value;
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
        valueListenable: videoPlayerController,
        builder: (BuildContext context,
            VideoPlayerController? videoPlayerController, Widget? child) {
          if (videoPlayerController != null) {
            _buildFlickManager();
            if (flickManager != null) {
              Widget flickVideoPlayer = VisibilityDetector(
                key: ObjectKey(flickManager),
                onVisibilityChanged: (VisibilityInfo info) {
                  if (info.visibleFraction == 0) {
                    flickManager?.flickControlManager?.autoPause();
                  } else if (info.visibleFraction == 1) {
                    flickManager?.flickControlManager?.autoResume();
                  }
                },
                child: FlickVideoPlayer(
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
                  flickVideoWithControlsFullscreen:
                      const FlickVideoWithControls(
                    videoFit: BoxFit.contain,
                    controls: FlickLandscapeControls(),
                  ),
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
      videoPlayerController.value = null;
      flickManager = null;
    }
  }
}
