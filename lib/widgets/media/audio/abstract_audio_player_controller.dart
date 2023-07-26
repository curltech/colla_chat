import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

abstract class AbstractAudioPlayerController
    extends AbstractMediaPlayerController {
  AbstractAudioPlayerController() : super() {
    fileType = FileType.custom;
    allowedExtensions = ['mp3', 'wav', 'opus', 'aac', 'm4a'];
  }

  bool _closedCaptionFile = false;

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play();

  pause();

  resume();

  stop();

  seek(Duration position, {int? index});

  Future<double> getSpeed() {
    return Future.value(mediaPlayerState.playbackSpeed);
  }

  setSpeed(double speed) {
    mediaPlayerState.playbackSpeed = speed;
  }

  Future<double> getVolume() {
    return Future.value(mediaPlayerState.volume);
  }

  setVolume(double volume) {
    mediaPlayerState.volume = volume;
  }

  bool get closedCaptionFile {
    return _closedCaptionFile;
  }

  set closedCaptionFile(bool closedCaptionFile) {
    _closedCaptionFile = closedCaptionFile;
    notifyListeners();
  }

  Future<void> _action() async {
    if (mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = false,
    bool showVolumeButton = true,
  }) {
    var progressText = this.progressText;
    Widget stopBtn = IconButton(
      tooltip: AppLocalizations.t('Stop'),
      icon: const Icon(
        Icons.stop_rounded,
        size: 32,
        //color: Colors.white,
      ),
      onPressed: () async {
        await stop();
      },
    );
    Widget gap = const SizedBox(
      width: 0,
    );
    List<Widget> controls = [];
    if (mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.playing) {
      controls.add(
        IconButton(
          tooltip: AppLocalizations.t('Pause'),
          icon: const Icon(
            Icons.pause_rounded,
            size: 32,
            //color: Colors.white,
          ),
          onPressed: () async {
            await pause();
          },
        ),
      );
      controls.add(
        gap,
      );
      controls.add(
        stopBtn,
      );
      controls.add(
        gap,
      );
    } else {
      controls.add(
        IconButton(
          tooltip: AppLocalizations.t('Play'),
          icon: const Icon(
            Icons.play_arrow_rounded,
            size: 32,
            //color: Colors.white,
          ),
          onPressed: () async {
            await play();
          },
        ),
      );
      controls.add(
        gap,
      );

      if (mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.pause) {
        controls.add(
          stopBtn,
        );
        controls.add(
          gap,
        );
      }
    }
    controls.add(
      CommonAutoSizeText(
        progressText,
        // style: const TextStyle(color: Colors.white),
      ),
    );
    var container = SizedBox(
      width: 240,
      height: 50,
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: controls),
    );
    return container;
  }
}
