import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';

///平台标准的video_player的实现，缺省采用MediaKit
class PlatformVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  PlatformVideoPlayerWidget({
    super.key,
  });

  @override
  State createState() => _PlatformVideoPlayerWidgetState();

  @override
  String get routeName => 'video_player';

  @override
  IconData get iconData => Icons.videocam;

  @override
  String get title => 'VideoPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformVideoPlayerWidgetState extends State<PlatformVideoPlayerWidget> {
  ValueNotifier<int> index = ValueNotifier<int>(0);
  late final PlatformVideoPlayer platformVideoPlayer = PlatformVideoPlayer(
    onInitialized: onInitialized,
    onIndexChanged: (index) {
      this.index.value = index;
    },
  );
  SwiperController? swiperController;
  PlaylistController? playlistController;
  AbstractMediaPlayerController? mediaPlayerController;

  @override
  void initState() {
    super.initState();
  }

  onInitialized(AbstractMediaPlayerController mediaPlayerController,
      SwiperController swiperController) {
    this.swiperController = swiperController;
    this.mediaPlayerController = mediaPlayerController;
    playlistController = mediaPlayerController.playlistController;
  }

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [];
    Widget btn = ValueListenableBuilder(
        valueListenable: index,
        builder: (BuildContext context, int index, Widget? child) {
          if (index == 0) {
            return IconButton(
              tooltip: AppLocalizations.t('Video player'),
              onPressed: () async {
                await swiperController?.move(1);
              },
              icon: const Icon(Icons.video_call),
            );
          } else {
            return IconButton(
              tooltip: AppLocalizations.t('Playlist'),
              onPressed: () async {
                await swiperController?.move(0);
              },
              icon: const Icon(Icons.featured_play_list_outlined),
            );
          }
        });
    children.add(btn);
    children.add(
      const SizedBox(
        width: 5.0,
      ),
    );
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('Close'),
        onPressed: () async {
          mediaPlayerController?.close();
          playlistController?.clear();
        },
        icon: const Icon(Icons.close),
      ),
    );

    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();

    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformVideoPlayer,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class PlatformVideoPlayer extends StatefulWidget {
  bool showPlaylist;
  List<String>? filenames;
  void Function(int index)? onIndexChanged;
  void Function(AbstractMediaPlayerController mediaPlayerController,
      SwiperController swiperController)? onInitialized;

  PlatformVideoPlayer(
      {super.key,
      this.filenames,
      this.showPlaylist = true,
      this.onIndexChanged,
      this.onInitialized}) {
    if (platformParams.windows) {
      WindowsVideoPlayer.registerWith();
    }
  }

  @override
  State createState() => _PlatformVideoPlayerState();
}

class _PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
  final SwiperController swiperController = SwiperController();
  final PlaylistController playlistController = PlaylistController();
  late final AbstractMediaPlayerController mediaPlayerController =
      MediaKitVideoPlayerController(playlistController);

  @override
  void initState() {
    super.initState();
    if (widget.filenames != null) {
      playlistController.addMediaFiles(filenames: widget.filenames!);
    }
    widget.onInitialized?.call(mediaPlayerController, swiperController);
  }

  @override
  Widget build(BuildContext context) {
    PlatformMediaPlayer platformMediaPlayer = PlatformMediaPlayer(
        showPlaylist: widget.showPlaylist,
        mediaPlayerController: mediaPlayerController,
        swiperController: swiperController,
        onIndexChanged: (int index) {
          widget.onIndexChanged?.call(index);
        });

    return platformMediaPlayer;
  }

  @override
  void dispose() {
    swiperController.dispose();
    playlistController.dispose();
    mediaPlayerController.dispose();
    super.dispose();
  }
}
