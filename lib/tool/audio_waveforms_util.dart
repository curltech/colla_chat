import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

///Flutter AudioWaveforms
class AudioWaveformsUtil {
  static buildAudioWaveforms({
    Key? key,
    required Size size,
    required RecorderController recorderController,
    WaveStyle waveStyle = const WaveStyle(),
    bool enableGesture = false,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
    Color? backgroundColor,
    bool shouldCalculateScrolledPosition = false,
  }) async {
    RecorderController recorderController = RecorderController();
    await recorderController.record();
    await recorderController.pause();
    final path = await recorderController.stop();
    recorderController.refresh();
    WaveStyle waveStyle = const WaveStyle(
      waveColor: Colors.white,
      showDurationLabel: true,
      spacing: 8.0,
      showBottom: false,
      extendWaveform: true,
      showMiddleLine: false,
    );
    return AudioWaveforms(
      key: key,
      size: size,
      padding: padding,
      margin: margin,
      decoration: decoration,
      backgroundColor: backgroundColor,
      shouldCalculateScrolledPosition: shouldCalculateScrolledPosition,
      recorderController: recorderController,
      waveStyle: waveStyle,
      enableGesture: enableGesture,
    );
  }

  static buildAudioFileWaveforms({
    Key? key,
    required Size size,
    required PlayerController playerController,
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
  }) async {
    PlayerController playerController = PlayerController();
    await playerController.startPlayer();
    await playerController.pausePlayer();
    await playerController.stopPlayer();
    await playerController.setVolume(1.0);
    await playerController.seekTo(5000);
    final duration = await playerController.getDuration(DurationType.max);
    WaveStyle waveStyle = const WaveStyle(
      waveColor: Colors.white,
      showDurationLabel: true,
      spacing: 8.0,
      showBottom: false,
      extendWaveform: true,
      showMiddleLine: false,
    );
    return AudioFileWaveforms(
      key: key,
      size: size,
      padding: padding,
      margin: margin,
      decoration: decoration,
      backgroundColor: backgroundColor,
      playerWaveStyle:playerWaveStyle,
      enableSeekGesture:enableSeekGesture,
      animationDuration:animationDuration,
      animationCurve:animationCurve,
      density:density,
      clipBehavior:clipBehavior,
      playerController: playerController,
    );
  }
}
