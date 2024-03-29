import 'package:chewie/chewie.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

///基于Chewie实现的媒体播放器和记录器，
class ChewieVideoPlayerController extends OriginVideoPlayerController {
  ChewieVideoPlayerController() {
    fileType = FileType.any;
    allowedExtensions = ['mp3', 'wav', 'mp4', 'm4a', 'mov', 'mpeg', 'aac'];
  }

  ChewieController? _buildChewieController() {
    var controller = videoPlayerController.value;
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
        playedColor: myself.primary,
        handleColor: myself.primary,
        backgroundColor: myself.secondary,
        bufferedColor: Colors.green,
      ),
      placeholder: Container(
        color: Colors.black,
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
    Widget player = ValueListenableBuilder(
        valueListenable: videoPlayerController,
        builder: (BuildContext context,
            VideoPlayerController? videoPlayerController, Widget? child) {
          if (videoPlayerController != null) {
            ChewieController? chewieController = _buildChewieController();
            if (chewieController != null) {
              return Chewie(
                key: key,
                controller: chewieController,
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
