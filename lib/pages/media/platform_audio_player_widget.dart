import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_audio_player.dart';
import 'package:flutter/material.dart';

///平台标准的AudioPlayer的实现，支持标准的audioplayers，just_audio和webview
class PlatformAudioPlayerWidget extends StatelessWidget with DataTileMixin {
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

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [
      ValueListenableBuilder(
          valueListenable: platformAudioPlayer.index,
          builder: (BuildContext context, int index, Widget? child) {
            if (index == 0) {
              return IconButton(
                tooltip: AppLocalizations.t('Audio player'),
                onPressed: () {
                  platformAudioPlayer.controller
                      .move(1);
                },
                icon: const Icon(Icons.audiotrack),
              );
            } else {
              return IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () {
                  platformAudioPlayer.controller
                      .move(0);
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
        },
        icon: const Icon(Icons.close),
      ),
    ];
    children.add(
      IconButton(
        tooltip: AppLocalizations.t('More'),
        onPressed: () {
          platformAudioPlayer.playlistWidget
              .showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
    );
    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets(context);

    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformAudioPlayer,
    );
  }
}
