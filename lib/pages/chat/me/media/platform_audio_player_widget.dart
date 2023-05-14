import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/just_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/player/waveforms_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/webview_video_player.dart';
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

  @override
  void initState() {
    super.initState();
  }

  List<Widget>? _buildRightWidgets() {
    List<bool> isSelected = const [true, false, false, false];
    if (widget.mediaPlayerController is BlueFireAudioPlayerController) {
      isSelected = const [false, true, false, false];
    }
    if (widget.mediaPlayerController is JustAudioPlayerController) {
      isSelected = const [false, false, true, false];
    }
    if (widget.mediaPlayerController is WaveformsAudioPlayerController) {
      isSelected = const [false, false, false, true];
    }
    var toggleWidget = ToggleButtons(
      selectedBorderColor: Colors.white,
      borderColor: Colors.grey,
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          setState(() {
            widget.mediaPlayerController = globalWebViewVideoPlayerController;
          });
        } else if (newIndex == 1) {
          setState(() {
            widget.mediaPlayerController = globalBlueFireAudioPlayerController;
          });
        } else if (newIndex == 2) {
          setState(() {
            widget.mediaPlayerController = globalJustAudioPlayerController;
          });
        } else if (newIndex == 3) {
          setState(() {
            widget.mediaPlayerController = globalWaveformsAudioPlayerController;
          });
        }
      },
      children: const <Widget>[
        Icon(
          Icons.web_outlined,
          color: Colors.white,
        ),
        Icon(
          Icons.fireplace,
          color: Colors.white,
        ),
        Icon(
          Icons.audiotrack_outlined,
          color: Colors.white,
        ),
        Icon(
          Icons.multitrack_audio,
          color: Colors.white,
        ),
      ],
    );
    List<Widget> children = [
      IconButton(
        onPressed: () {
          widget.swiperController.next();
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
      toggleWidget,
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
    widget.mediaPlayerController.close();
    super.dispose();
  }
}
