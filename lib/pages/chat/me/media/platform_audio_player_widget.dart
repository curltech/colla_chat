import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///平台标准的AudioPlayer的实现，支持标准的audioplayers，just_audio和webview
class PlatformAudioPlayerWidget extends StatefulWidget with TileDataMixin {
  AbstractMediaPlayerController mediaPlayerController =
      globalBlueFireAudioPlayerController;
  final SwiperController swiperController = SwiperController();

  PlatformAudioPlayerWidget({super.key});

  @override
  State createState() => _PlatformAudioPlayerWidgetState();

  @override
  String get routeName => 'audio_player';

  @override
  IconData get iconData => Icons.audiotrack;

  @override
  String get title => 'AudioPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformAudioPlayerWidgetState extends State<PlatformAudioPlayerWidget> {
  AudioPlayerType audioPlayerType = AudioPlayerType.audioplayers;
  ValueNotifier<int> index = ValueNotifier<int>(0);

  @override
  void initState() {
    widget.swiperController.addListener(_update);
    super.initState();
  }

  _update() {
    index.value = widget.swiperController.index;
  }

  List<Widget>? _buildRightWidgets() {
    List<Widget> children = [
      ValueListenableBuilder(
          valueListenable: index,
          builder: (BuildContext context, int index, Widget? child) {
            if (index == 0) {
              return IconButton(
                tooltip: AppLocalizations.t('Audio player'),
                onPressed: () {
                  widget.swiperController.move(1);
                  this.index.value = 1;
                },
                icon: const Icon(Icons.audiotrack),
              );
            } else {
              return IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () {
                  widget.swiperController.move(0);
                  this.index.value = 0;
                },
                icon: const Icon(Icons.featured_play_list_outlined),
              );
            }
          }),
      const SizedBox(
        width: 5.0,
      )
    ];
    return children;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = _buildRightWidgets();
    PlatformMediaPlayer platformMediaPlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: true,
      mediaPlayerController: widget.mediaPlayerController,
      swiperController: widget.swiperController,
    );
    return AppBarView(
      titleWidget: CommonAutoSizeText(AppLocalizations.t(widget.title),
          style: const TextStyle(fontSize: AppFontSize.mdFontSize)),
      withLeading: true,
      rightWidgets: rightWidgets,
      child: platformMediaPlayer,
    );
  }

  @override
  void dispose() {
    widget.swiperController.removeListener(_update);
    widget.mediaPlayerController.close();
    super.dispose();
  }
}
