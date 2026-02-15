import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/awesome_video_player.dart';
import 'package:colla_chat/widgets/media/video/better_enhance_video_player.dart';
import 'package:colla_chat/widgets/media/video/better_plus_video_player.dart';
import 'package:colla_chat/widgets/media/video/chewie_video_player.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:colla_chat/widgets/media/video/vlc_video_player.dart';
import 'package:flutter/material.dart';

/// 平台的多个视频媒体播放器组件
class PlatformVideoPlayer extends StatelessWidget {
  final List<AbstractMediaPlayerController> mediaPlayerControllers = [];
  final List<PlatformMediaPlayer> platformMediaPlayers = [];
  final PlaylistController playlistController;
  final ValueNotifier<int> crossAxisCount = ValueNotifier<int>(1);

  PlatformVideoPlayer({
    super.key,
    required this.playlistController,
  }) {
    MediaKitVideoPlayerController mediaKitVideoPlayerController =
        MediaKitVideoPlayerController(playlistController);
    mediaPlayerControllers.add(mediaKitVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: mediaKitVideoPlayerController,
    ));
    if (platformParams.mobile) {
      AwesomeVideoPlayerController awesomeVideoPlayerController =
          AwesomeVideoPlayerController(playlistController);
      mediaPlayerControllers.add(awesomeVideoPlayerController);
      platformMediaPlayers.add(PlatformMediaPlayer(
        mediaPlayerController: awesomeVideoPlayerController,
      ));
    }
    if (platformParams.mobile) {
      MobileVlcPlayerController mobileVlcPlayerController =
          MobileVlcPlayerController(playlistController);
      mediaPlayerControllers.add(mobileVlcPlayerController);
      platformMediaPlayers.add(PlatformMediaPlayer(
        mediaPlayerController: mobileVlcPlayerController,
      ));
      BetterPlusVideoPlayerController betterPlusVideoPlayerController =
          BetterPlusVideoPlayerController(playlistController);
      mediaPlayerControllers.add(betterPlusVideoPlayerController);
      platformMediaPlayers.add(PlatformMediaPlayer(
        mediaPlayerController: betterPlusVideoPlayerController,
      ));
      BetterEnhanceVideoPlayerController betterEnhanceVideoPlayerController =
          BetterEnhanceVideoPlayerController(playlistController);
      mediaPlayerControllers.add(betterEnhanceVideoPlayerController);
      platformMediaPlayers.add(PlatformMediaPlayer(
        mediaPlayerController: betterEnhanceVideoPlayerController,
      ));
    }
    ChewieVideoPlayerController chewieVideoPlayerController =
        ChewieVideoPlayerController(playlistController);
    mediaPlayerControllers.add(chewieVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: chewieVideoPlayerController,
    ));
    OriginVideoPlayerController originVideoPlayerController =
        OriginVideoPlayerController(playlistController);
    mediaPlayerControllers.add(originVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: originVideoPlayerController,
    ));
    // WebViewVideoPlayerController webViewVideoPlayerController =
    //     WebViewVideoPlayerController(playlistController);
    // mediaPlayerControllers.add(webViewVideoPlayerController);
    // platformMediaPlayers.add(PlatformMediaPlayer(
    //   mediaPlayerController: webViewVideoPlayerController,
    // ));
  }

  void toggleCrossAxisCount() {
    if (crossAxisCount.value == 4) {
      crossAxisCount.value = 1;
    } else {
      crossAxisCount.value = crossAxisCount.value + 1;
    }
  }

  void close() {
    for (var mediaPlayerController in mediaPlayerControllers) {
      mediaPlayerController.close();
    }
  }

  Widget _buildVideoPlayer(BuildContext context) {
    Widget mediaView = ValueListenableBuilder(
        valueListenable: crossAxisCount,
        builder: (BuildContext context, crossAxisCount, Widget? child) {
          return GridView.builder(
              itemCount: platformMediaPlayers.length,
              //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  //横轴元素个数
                  crossAxisCount: crossAxisCount,
                  //纵轴间距
                  mainAxisSpacing: 1.0,
                  //横轴间距
                  crossAxisSpacing: 1.0,
                  //子组件宽高长度比例
                  childAspectRatio: 1),
              itemBuilder: (BuildContext context, int index) {
                return platformMediaPlayers[index];
              });
        });

    return Center(
      child: mediaView,
    );
  }

  void play() {
    int? currentIndex = playlistController.currentIndex?.value;
    currentIndex ??= 0;
    int? length = playlistController.length;
    if (length != null) {
      int i = 0;
      for (var mediaPlayerController in mediaPlayerControllers) {
        PlatformMediaSource? mediaSource;
        while (mediaSource == null ||
            mediaSource.mediaSourceType != MediaSourceType.file) {
          mediaSource =
              playlistController.currentController!.data[currentIndex + i];
          ++i;
          mediaPlayerController.playMediaSource(mediaSource);
          if (currentIndex + i >= length) {
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoPlayer(context);
  }
}
