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

  AbstractAudioPlayerController() : super() {
    fileType = FileType.any;
    allowedExtensions = ['mp3', 'wav'];
  }

  VideoPlayerValue _playerValue =
      const VideoPlayerValue(duration: Duration.zero);
  bool _closedCaptionFile = false;

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play();

  pause();

  resume();

  stop();

  seek(Duration position, {int? index});

  Future<double> getSpeed() {
    return Future.value(_playerValue.playbackSpeed);
  }

  setSpeed(double speed) {
    _playerValue = _playerValue.copyWith(
        duration: _playerValue.duration, playbackSpeed: speed);
  }

  Future<double> getVolume() {
    return Future.value(_playerValue.volume);
  }

  setVolume(double volume) {
    _playerValue =
        _playerValue.copyWith(duration: _playerValue.duration, volume: volume);
  }

  VideoPlayerValue get playerValue {
    return _playerValue;
  }

  set playerValue(VideoPlayerValue value) {
    _playerValue = _playerValue.copyWith(
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
    if (_playerValue.isPlaying) {
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
    var controlText = AppLocalizations.t(_durationText);
    Icon playIcon;
    if (_playerValue.isPlaying) {
      playIcon = const Icon(Icons.pause, size: 32);
    } else {
      playIcon = const Icon(Icons.play_arrow, size: 32);
    }
    List<Widget> controls = [];
    if (_playerValue.isPlaying) {
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
