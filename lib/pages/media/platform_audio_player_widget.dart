import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/platform_audio_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

///平台标准的AudioPlayer的实现，支持标准的audioplayers，just_audio和webview
class PlatformAudioPlayerWidget extends StatelessWidget with DataTileMixin {
  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    onSelected: _onSelected,
    playlistController: playlistController,
  );
  late final PlatformAudioPlayer platformAudioPlayer = PlatformAudioPlayer(
    playlistController: playlistController,
  );

  PlatformAudioPlayerWidget({super.key});

  @override
  String get routeName => 'audio_player';

  @override
  IconData get iconData => Icons.audiotrack;

  @override
  String get title => 'AudioPlayer';

  @override
  bool get withLeading => true;

  void _onSelected(int index, String filename) {
    // swiperController.move(1);
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [
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
          playlistWidget.showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
    );
    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets(context);

    return AppBarAdaptiveView(
      title: title,
      helpPath: routeName,
      rightWidgets: rightWidgets,
      main: playlistWidget,
      body: platformAudioPlayer,
    );
  }
}
