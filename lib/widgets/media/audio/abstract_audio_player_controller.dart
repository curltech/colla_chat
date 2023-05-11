import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

abstract class AbstractAudioPlayerController
    extends AbstractMediaPlayerController {
  int _duration = -1;
  String _durationText = '';
  PlayerStatus playerStatus = PlayerStatus.stop;

  AbstractAudioPlayerController() : super() {
    fileType = FileType.any;
    allowedExtensions = ['mp3', 'wav'];
  }

  VideoPlayerValue _value = const VideoPlayerValue(duration: Duration.zero);
  bool _closedCaptionFile = false;

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play();

  pause();

  resume();

  stop();

  seek(Duration position, {int? index});

  Future<double> getSpeed() {
    return Future.value(_value.playbackSpeed);
  }

  setSpeed(double speed) {
    _value = _value.copyWith(duration: _value.duration, playbackSpeed: speed);
  }

  Future<double> getVolume() {
    return Future.value(_value.volume);
  }

  setVolume(double volume) {
    _value = _value.copyWith(duration: _value.duration, volume: volume);
  }

  VideoPlayerValue get value {
    return _value;
  }

  set value(VideoPlayerValue value) {
    _value = _value.copyWith(
        duration: value.duration,
        size: value.size,
        position: value.position,
        caption: value.caption,
        captionOffset: value.captionOffset,
        buffered: value.buffered,
        isInitialized: value.isInitialized,
        isPlaying: value.isPlaying,
        isLooping: value.isLooping,
        isBuffering: value.isBuffering,
        volume: value.volume,
        playbackSpeed: value.playbackSpeed,
        rotationCorrection: value.rotationCorrection,
        errorDescription: value.errorDescription);
  }

  bool get closedCaptionFile {
    return _closedCaptionFile;
  }

  set closedCaptionFile(bool closedCaptionFile) {
    _closedCaptionFile = closedCaptionFile;
    notifyListeners();
  }

  Future<void> _action() async {
    if (playerStatus == PlayerStatus.playing) {
      await pause();
    } else if (playerStatus == PlayerStatus.stop) {
      await play();
    } else if (playerStatus == PlayerStatus.pause) {
      await resume();
    }
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = false,
    bool showVolumeButton = true,
  }) {
    var controlText = AppLocalizations.t(_durationText);
    Icon playIcon;
    if (playerStatus == PlayerStatus.playing) {
      playIcon = const Icon(Icons.pause, size: 32);
    } else {
      playIcon = const Icon(Icons.play_arrow, size: 32);
    }
    List<Widget> controls = [];
    if (playerStatus == PlayerStatus.playing ||
        playerStatus == PlayerStatus.pause) {
      controls.add(
        IconButton(
          icon: const Icon(Icons.stop, size: 32),
          onPressed: () async {
            await stop();
          },
        ),
      );
      controls.add(
        const SizedBox(
          width: 15,
        ),
      );
    }
    controls.add(
      IconButton(
        icon: playIcon,
        onPressed: () async {
          await _action();
        },
      ),
    );
    controls.add(
      const SizedBox(
        width: 15,
      ),
    );
    controls.add(
      CommonAutoSizeText(controlText),
    );
    var container = SizedBox(
      width: 200,
      height: 50,
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: controls),
    );
    return container;
  }
}
