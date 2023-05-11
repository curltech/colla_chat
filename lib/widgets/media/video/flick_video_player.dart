import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';

///基于flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends OriginVideoPlayerController {
  FlickVideoPlayerController() {
    fileType = FileType.media;
  }

  FlickManager? _buildFlickManager() {
    var controller = this.videoPlayerController;
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
    Widget flickVideoWithControls = const FlickVideoWithControls(
        videoFit: BoxFit.contain, controls: FlickPortraitControls());
    FlickManager? flickManager = _buildFlickManager();
    Widget player = flickManager != null
        ? FlickVideoPlayer(
            key: key,
            flickManager: flickManager,
            flickVideoWithControls: flickVideoWithControls,
          )
        : Center(
            child: CommonAutoSizeText(
            AppLocalizations.t('Please select a media file'),
            style: const TextStyle(color: Colors.white),
          ));

    return player;
  }
}
