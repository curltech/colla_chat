import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

///生成语音的波形界面
class AudioWaveformsUtil {
  ///录音，同时生成波形界面
  static AudioWaveforms buildAudioWaveforms({
    Key? key,
    required Size size,
    required RecorderController recorderController,
    WaveStyle? waveStyle,
    bool enableGesture = false,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
    Color? backgroundColor,
    bool shouldCalculateScrolledPosition = false,
  }) {
    waveStyle = waveStyle ??
        const WaveStyle(
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

  ///播放音频文件，并产生波形界面
  static AudioFileWaveforms buildAudioFileWaveforms({
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
  }) {
    return AudioFileWaveforms(
      key: key,
      size: size,
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
