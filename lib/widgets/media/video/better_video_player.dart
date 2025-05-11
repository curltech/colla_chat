import 'package:better_player_plus/better_player_plus.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';

///基于better实现的媒体播放器和记录器，
class BetterVideoPlayerController extends AbstractMediaPlayerController {
  BetterPlayerController? betterPlayerController;

  BetterVideoPlayerController(super.playlistController);

  void _buildBetterPlayerController() {
    betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
      ),
      betterPlayerPlaylistConfiguration: BetterPlayerPlaylistConfiguration(),
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
          if (betterPlayerController != null) {
            _buildBetterPlayerController();
            if (betterPlayerController != null) {
              return Stack(children: [
                BetterPlayer(
                  key: key,
                  controller: betterPlayerController!,
                ),
                buildPlaylistController()
              ]);
            }
          }
          if (playlistController.current != null) {
            return LoadingUtil.buildLoadingIndicator();
          }
          return Center(child: buildOpenFileWidget());
        });

    return player;
  }

  @override
  void close() {
    super.close();
    if (betterPlayerController != null) {
      betterPlayerController!.dispose();
      betterPlayerController = null;
    }
  }

  @override
  pause() {
    betterPlayerController?.pause();
  }

  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    betterPlayerController?.pause();
  }

  @override
  resume() {
    betterPlayerController?.play();
  }

  @override
  stop() {
    betterPlayerController?.playNextVideo();
  }
}
