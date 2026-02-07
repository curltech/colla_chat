import 'package:awesome_video_player/awesome_video_player.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';

///基于awesome better实现的媒体播放器和记录器，
class AwesomeVideoPlayerController extends AbstractMediaPlayerController {
  late final BetterPlayerController betterPlayerController =
      BetterPlayerController(
    BetterPlayerConfiguration(
      autoPlay: autoPlay,
      looping: true,
    ),
    betterPlayerPlaylistConfiguration: BetterPlayerPlaylistConfiguration(),
  );

  AwesomeVideoPlayerController(super.playlistController);

  @override
  Future<bool?> isPictureInPictureSupported() async {
    return await betterPlayerController.isPictureInPictureSupported();
  }

  @override
  Future<void> enablePictureInPicture() async {
    await betterPlayerController.enablePictureInPicture(key);
  }

  @override
  Future<void> disablePictureInPicture() async {
    await betterPlayerController.disablePictureInPicture();
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
          if (filename != null) {
            return Stack(children: [
              BetterPlayer(
                key: key,
                controller: betterPlayerController,
              ),
              buildPlaylistController()
            ]);
          }
          return Center(child: buildOpenFileWidget());
        });

    return player;
  }

  @override
  Future<void> close() async {
    await super.close();
    betterPlayerController.dispose();
  }

  @override
  pause() {
    if (betterPlayerController.videoPlayerController != null) {
      betterPlayerController.pause();
    }
  }

  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    if (autoPlay) {
      BetterPlayerDataSourceType? sourceType = StringUtil.enumFromString(
          BetterPlayerDataSourceType.values, mediaSource.mediaSourceType.name);
      await betterPlayerController.setupDataSource(
          BetterPlayerDataSource(sourceType!, mediaSource.filename));
      betterPlayerController.play();
    }
    filename.value = mediaSource.filename;
  }

  @override
  play() {
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  @override
  resume() {
    if (betterPlayerController.videoPlayerController != null) {
      betterPlayerController.play();
    }
  }

  @override
  stop() {
    if (betterPlayerController.videoPlayerController != null) {
      betterPlayerController.dispose();
    }
  }
}
