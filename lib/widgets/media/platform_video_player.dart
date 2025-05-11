import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/better_video_player.dart';
import 'package:colla_chat/widgets/media/video/chewie_video_player.dart';
import 'package:colla_chat/widgets/media/video/flick_video_player.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:colla_chat/widgets/media/video/webview_video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlatformVideoPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  final List<AbstractMediaPlayerController> mediaPlayerControllers = [];
  final bool showPlaylist;
  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget;
  final List<PlatformMediaPlayer> platformMediaPlayers = [];
  final RxInt index = 0.obs;

  PlatformVideoPlayer({
    super.key,
    this.showPlaylist = true,
    List<String>? filenames,
  }) {
    if (filenames != null) {
      playlistController.addMediaFiles(filenames: filenames);
    }
    MediaKitVideoPlayerController mediaKitVideoPlayerController =
        MediaKitVideoPlayerController(playlistController);
    mediaPlayerControllers.add(mediaKitVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: mediaKitVideoPlayerController,
    ));
    BetterVideoPlayerController betterVideoPlayerController =
        BetterVideoPlayerController(playlistController);
    mediaPlayerControllers.add(betterVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: betterVideoPlayerController,
    ));
    ChewieVideoPlayerController chewieVideoPlayerController =
        ChewieVideoPlayerController(playlistController);
    mediaPlayerControllers.add(chewieVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: chewieVideoPlayerController,
    ));
    FlickVideoPlayerController flickVideoPlayerController =
        FlickVideoPlayerController(playlistController);
    mediaPlayerControllers.add(flickVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: flickVideoPlayerController,
    ));
    OriginVideoPlayerController originVideoPlayerController =
        OriginVideoPlayerController(playlistController);
    mediaPlayerControllers.add(originVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: originVideoPlayerController,
    ));
    WebViewVideoPlayerController webViewVideoPlayerController =
        WebViewVideoPlayerController(playlistController);
    mediaPlayerControllers.add(webViewVideoPlayerController);
    platformMediaPlayers.add(PlatformMediaPlayer(
      mediaPlayerController: webViewVideoPlayerController,
    ));
    playlistWidget = PlaylistWidget(
      onSelected: _onSelected,
      playlistController: playlistController,
    );
  }

  _onSelected(int index, String filename) {
    swiperController.move(1);
  }

  close() {
    for (var mediaPlayerController in mediaPlayerControllers) {
      mediaPlayerController.close();
    }
  }

  Widget _buildVideoPlayer(BuildContext context) {
    Widget mediaView = Swiper(
      itemCount: 2,
      index: index.value,
      controller: swiperController,
      onIndexChanged: (int index) {
        this.index.value = index;
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return playlistWidget;
        }
        if (index == 1) {
          int crossAxisCount =
              (appDataProvider.secondaryBodyWidth / 400).ceil();
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
        }
        return nilBox;
      },
    );

    return Center(
      child: mediaView,
    );
  }

  play() {
    int? currentIndex = playlistController.currentIndex.value;
    currentIndex ??= 0;
    int length = playlistController.data.length;
    for (int i = 0; i < mediaPlayerControllers.length; ++i) {
      if (currentIndex + i < length) {
        PlatformMediaSource mediaSource =
            playlistController.data[currentIndex + i];
        mediaPlayerControllers[currentIndex + i].playMediaSource(mediaSource);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoPlayer(context);
  }
}
