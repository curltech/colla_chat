import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

///基于flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends OriginVideoPlayerController {
  FlickVideoPlayerController() {
    fileType = FileType.any;
    allowedExtensions = ['mp3', 'wav', 'mp4', 'm4a', 'mov', 'mpeg', 'aac'];
  }

  FlickManager? _buildFlickManager() {
    var controller = videoPlayerController.value;
    if (controller == null) {
      return null;
    }
    FlickManager flickManager = FlickManager(
      videoPlayerController: controller,
      onVideoEnd: next,
      autoPlay: false,
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
    Widget player = ValueListenableBuilder(
        valueListenable: videoPlayerController,
        builder: (BuildContext context,
            VideoPlayerController? videoPlayerController, Widget? child) {
          if (videoPlayerController != null) {
            Widget flickVideoWithControls = const FlickVideoWithControls(
                videoFit: BoxFit.contain, controls: FlickPortraitControls());
            FlickManager? flickManager = _buildFlickManager();
            if (flickManager != null) {
              return FlickVideoPlayer(
                key: key,
                flickManager: flickManager,
                flickVideoWithControls: flickVideoWithControls,
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
}
