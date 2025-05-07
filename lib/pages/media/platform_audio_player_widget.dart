import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_audio_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

///平台标准的AudioPlayer的实现，支持标准的audioplayers，just_audio和webview
class PlatformAudioPlayerWidget extends StatelessWidget with TileDataMixin {
  final PlatformAudioPlayer platformAudioPlayer = PlatformAudioPlayer();

  PlatformAudioPlayerWidget({super.key});

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
          valueListenable: platformAudioPlayer.playlistMediaPlayer.index,
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
          platformAudioPlayer.playlistController.clear();
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
      helpPath: routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformAudioPlayer,
    );
  }
}
