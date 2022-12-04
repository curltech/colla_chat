import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/src/widgets/framework.dart';

///WaveformsAudio音频播放器，Android, iOS, Linux, macOS, Windows, and web.
///还可以产生音频播放的波形图形组件
class WaveformsAudioPlayerController extends AbstractMediaPlayerController {
  late PlayerController playerController;
  double _volume = 1.0;

  WaveformsAudioPlayerController() {
    playerController = PlayerController();
  }

  ///设置当前的通用MediaSource，并转换成特定实现的媒体源，并进行设置
  @override
  setCurrentIndex(int? index) async {
    super.setCurrentIndex(index);
    if (currentIndex != null) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        playerController.preparePlayer(currentMediaSource.filename, _volume);
        notifyListeners();
      }
    }
  }

  @override
  play() async {
    if (currentIndex != null) {
      await playerController.startPlayer();
    }
  }

  @override
  pause() async {
    await playerController.pausePlayer();
  }

  @override
  stop() async {
    await playerController.stopPlayer();
  }

  @override
  resume() async {
    if (currentIndex != null) {
      await playerController.startPlayer();
    }
  }

  @override
  dispose() async {
    super.dispose();
    playerController.dispose();
  }

  @override
  seek(Duration? position, {int? index}) async {
    if (index != null) {
      setCurrentIndex(index!);
    }
    if (position != null) {
      try {
        await playerController.seekTo(position.inMilliseconds);
      } catch (e) {
        logger.e('seek failure:$e');
      }
    }
  }

  @override
  setShuffleModeEnabled(bool enabled) async {}

  @override
  Future<Duration?> getDuration() async {
    int milliseconds = await playerController.getDuration(DurationType.max);

    return Duration(milliseconds: milliseconds);
  }

  @override
  Future<Duration?> getPosition() async {
    int milliseconds = await playerController.getDuration(DurationType.current);

    return Duration(milliseconds: milliseconds);
  }

  @override
  Future<Duration?> getBufferedPosition() async {
    return Future.value(const Duration(milliseconds: 0));
  }

  @override
  Future<double> getVolume() async {
    return Future.value(_volume);
  }

  @override
  setVolume(double volume) async {
    if (_volume != volume) {
      bool success = await playerController.setVolume(volume);
      if (success) {
        _volume = volume;
      }
    }
  }

  @override
  Future<double> getSpeed() async {
    return Future.value(1.0);
  }

  @override
  setSpeed(double speed) async {}

  @override
  close() {}

  @override
  Widget buildMediaView({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
    PlayerWaveStyle playerWaveStyle = const PlayerWaveStyle(),
    bool enableSeekGesture = true,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
    Color? backgroundColor,
    Duration animationDuration = const Duration(milliseconds: 500),
    Curve animationCurve = Curves.ease,
    double density = 2,
    Clip clipBehavior = Clip.none,
  }) {
    return AudioFileWaveforms(
      key: key,
      size: Size(width!, height!),
      padding: padding,
      margin: margin,
      decoration: decoration,
      backgroundColor: backgroundColor,
      playerWaveStyle: playerWaveStyle,
      enableSeekGesture: enableSeekGesture,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      density: density,
      clipBehavior: clipBehavior,
      playerController: playerController,
    );
  }
}
