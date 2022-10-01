import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
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

///带波形的音频播放器的简单界面，可以用于聊天界面播放音频文件或者录音
///只能用于移动设备
class AudioPlayerWaveforms extends StatefulWidget {
  late final PlayerController controller;
  final String filename;

  AudioPlayerWaveforms({
    Key? key,
    PlayerController? controller,
    required this.filename,
  }) : super(key: key) {
    this.controller = controller ?? PlayerController();
    this.controller.onPlayerStateChanged.listen((state) {
      logger.i('PlayerStateChanged:${state.name}');
    });
    this.controller.onCurrentDurationChanged.listen((duration) {
      logger.i('onCurrentDurationChanged:$duration');
    });
    this.controller.preparePlayer(filename);
  }

  @override
  State createState() => AudioPlayerWaveformsState();
}

class AudioPlayerWaveformsState extends State<AudioPlayerWaveforms> {
  double volume = 1.0;

  @override
  void initState() {
    super.initState();
  }

  void showSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    String suffix = '',
    required double value,
    Stream<double>? stream,
    required ValueChanged<double> onChanged,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<double>(
          stream: stream,
          builder: (context, snapshot) => SizedBox(
            height: 100.0,
            child: Column(
              children: [
                Text('${snapshot.data?.toStringAsFixed(1)}$suffix',
                    style: const TextStyle(
                        fontFamily: 'Fixed',
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0)),
                RotatedBox(
                    quarterTurns: 0,
                    child: Slider(
                      divisions: divisions,
                      min: min,
                      max: max,
                      value: snapshot.data ?? value,
                      onChanged: onChanged,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeButton(BuildContext context, {String? label}) {
    return Ink(
        child: InkWell(
      child: Row(children: [
        const Icon(Icons.volume_up_rounded, size: 24),
        Text(label ?? '')
      ]),
      onTap: () {
        showSliderDialog(
          context: context,
          title: "Adjust volume",
          divisions: 10,
          min: 0.0,
          max: 1.0,
          value: volume,
          onChanged: (double value) {
            setState(() {
              volume = value;
            });
          },
        );
      },
    ));
  }

  Row _buildSimpleControlPanel(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVolumeButton(context),
          StreamBuilder<PlayerState>(
              stream: widget.controller.onPlayerStateChanged,
              builder: (context, snapshot) {
                PlayerState? playerState = snapshot.data;
                List<Widget> widgets = [];
                if (playerState != PlayerState.playing) {
                  widgets.add(Ink(
                      child: InkWell(
                    onTap: () {
                      widget.controller.startPlayer();
                    },
                    child: const Icon(Icons.play_arrow_rounded, size: 36),
                  )));
                } else if (playerState != PlayerState.readingComplete) {
                  widgets.add(Ink(
                      child: InkWell(
                    onTap: () {
                      widget.controller.pausePlayer();
                    },
                    child: const Icon(Icons.pause, size: 36),
                  )));
                } else {
                  widgets.add(Ink(
                      child: InkWell(
                    child: const Icon(Icons.replay, size: 36),
                    onTap: () {
                      widget.controller.seekTo(0);
                    },
                  )));
                }
                return Row(
                  children: widgets,
                );
              }),
        ]);
  }

  Widget _buildPlayerSlider(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.controller.onCurrentDurationChanged,
      builder: (context, snapshot) {
        var position = Duration.zero;
        if (snapshot.data != null) {
          position = Duration(milliseconds: snapshot.data!);
        }
        var maxDuration = Duration(milliseconds: widget.controller.maxDuration);
        return MediaPlayerSlider(
          duration: maxDuration,
          position: position,
          bufferedPosition: Duration.zero,
          onChangeEnd: (Duration duration) {
            widget.controller.seekTo(duration.inMilliseconds);
          },
        );
      },
    );
  }

  Widget _buildAudioFileWaveforms(BuildContext context) {
    return AudioFileWaveforms(
      size: Size(MediaQuery.of(context).size.width / 2, 70),
      playerController: widget.controller,
      density: 1.5,
      playerWaveStyle: const PlayerWaveStyle(
        scaleFactor: 0.8,
        fixedWaveColor: Colors.white30,
        liveWaveColor: Colors.white,
        waveCap: StrokeCap.butt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAudioFileWaveforms(context),
        Row(children: [
          _buildVolumeButton(context),
          _buildSimpleControlPanel(context),
          _buildPlayerSlider(context)
        ])
      ],
    );
  }
}
