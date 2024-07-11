import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

///平台标准的AudioPlayer的实现，支持标准的audioplayers，just_audio和webview
class PlatformAudioPlayerWidget extends StatelessWidget with TileDataMixin {
  final PlaylistController playlistController = PlaylistController();
  late final PlatformAudioPlayer platformAudioPlayer;

  PlatformAudioPlayerWidget({super.key}) {
    platformAudioPlayer = PlatformAudioPlayer(
      playlistController: playlistController,
    );
  }

  @override
  String get routeName => 'audio_player';

  @override
  IconData get iconData => Icons.audiotrack;

  @override
  String get title => 'AudioPlayer';

  @override
  bool get withLeading => true;

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [
      ValueListenableBuilder(
          valueListenable: platformAudioPlayer.platformMediaPlayer.index,
          builder: (BuildContext context, int index, Widget? child) {
            if (index == 0) {
              return IconButton(
                tooltip: AppLocalizations.t('Audio player'),
                onPressed: () {
                  platformAudioPlayer.swiperController.move(1);
                },
                icon: const Icon(Icons.audiotrack),
              );
            } else {
              return IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () {
                  platformAudioPlayer.swiperController.move(0);
                },
                icon: const Icon(Icons.featured_play_list_outlined),
              );
            }
          }),
      const SizedBox(
        width: 5.0,
      ),
      IconButton(
        tooltip: AppLocalizations.t('Close'),
        onPressed: () async {
          platformAudioPlayer.mediaPlayerController.close();
          playlistController.clear();
        },
        icon: const Icon(Icons.close),
      ),
    ];
    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();

    return AppBarView(
      titleWidget: CommonAutoSizeText(AppLocalizations.t(title),
          style: const TextStyle(fontSize: AppFontSize.mdFontSize)),
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformAudioPlayer,
    );
  }
}

class PlatformAudioPlayer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  PlaylistController? playlistController;
  List<String>? filenames;
  late final PlatformMediaPlayer platformMediaPlayer;
  AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;
  late AbstractMediaPlayerController mediaPlayerController;

  PlatformAudioPlayer({
    super.key,
    this.filenames,
    this.playlistController,
  }) {
    playlistController ??= PlaylistController();
    if (filenames != null) {
      playlistController!.addMediaFiles(filenames: filenames!);
    }
    mediaPlayerController = BlueFireAudioPlayerController(playlistController!);
    platformMediaPlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: true,
      mediaPlayerController: mediaPlayerController,
      swiperController: swiperController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return platformMediaPlayer;
  }
}
