import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/audio/just_audio_player_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class JustAudioPlayer extends StatefulWidget {
  late final JustAudioPlayerController controller;

  JustAudioPlayer({
    Key? key,
    JustAudioPlayerController? controller,
  }) : super(key: key) {
    controller = controller ?? JustAudioPlayerController();
  }

  @override
  JustAudioPlayerState createState() => JustAudioPlayerState();
}

class JustAudioPlayerState extends State<JustAudioPlayer>
    with WidgetsBindingObserver {
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors during playback.
    _subscription = widget.controller.player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace stackTrace) {
        logger.e('A stream error occurred: $e');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      widget.controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox.fromSize(
      size: size,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Spacer(flex: 2),

          //Seek bar
          SizedBox(
            width: size.width,
            height: 250,
            child: SeekBar(controller: widget.controller),
          ),

          const Spacer(),

          //Controll Buttons
          ControlButtons(controller: widget.controller),

          const Spacer(),

          //Exit button
          InkWell(
            child: Icon(Icons.clear),
            onTap: () async {},
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class ControlButtons extends StatefulWidget {
  const ControlButtons({super.key, required this.controller});

  final JustAudioPlayerController controller;

  @override
  State<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  static Set<double> allowedSpeeds = {.25, .5, .75, 1.0, 1.25, 1.5, 1.75, 2.0};

  int currentSpeedIndex = 3;

  Widget _buildMainButton(
      PlayerState? state, ProcessingState? processingState) {
    if (state == null ||
        processingState == null ||
        processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return const SizedBox(
        width: 86,
        height: 112,
        child: Align(
          alignment: Alignment(0, -.55),
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
          ),
        ),
      );
    }

    IconData icon = Icons.replay;
    String label = "replay";
    Alignment? alignment;
    Function onTap = () => widget.controller.seek(null);

    if (!state.playing) {
      icon = CupertinoIcons.play_arrow_solid;
      alignment = const Alignment(.2, 0);
      label = "play";
      onTap = () => widget.controller.play();
    } else if (processingState != ProcessingState.completed) {
      icon = CupertinoIcons.pause_solid;
      label = "pause";
      onTap = () => widget.controller.pause();
    }

    return InkWell(
      child: Icon(icon),
      onTap: () => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget.controller.player.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;

          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(flex: 2),

              //Decrease speed
              InkWell(
                child: Icon(CupertinoIcons.backward_end_fill),
                onTap: () {
                  if (currentSpeedIndex > 0) {
                    currentSpeedIndex--;
                    widget.controller.setRate(
                      allowedSpeeds.elementAt(currentSpeedIndex),
                    );
                  }
                },
              ),

              const Spacer(),

              //play/pause button
              _buildMainButton(playerState, processingState),

              const Spacer(),

              //Save Button
              InkWell(
                child: Icon(CupertinoIcons.checkmark_alt),
                onTap: () => widget.controller.stop(),
              ),

              const Spacer(),

              //Increase speed
              InkWell(
                child: Icon(CupertinoIcons.forward_end_fill),
                onTap: () {
                  if (currentSpeedIndex < allowedSpeeds.length - 1) {
                    currentSpeedIndex++;
                    widget.controller.setRate(
                      allowedSpeeds.elementAt(currentSpeedIndex),
                    );
                    print(allowedSpeeds.elementAt(currentSpeedIndex));
                  }
                },
              ),
              const Spacer(flex: 2),
            ],
          );
        });
  }
}

class SeekBar extends StatefulWidget {
  final JustAudioPlayerController controller;
  final ValueChanged<Duration>? onChanged;

  const SeekBar({Key? key, required this.controller, this.onChanged})
      : super(key: key);

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  double? _dragValue;
  late SliderThemeData sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 4.0,
      inactiveTrackColor: Colors.grey,
      activeTrackColor: Colors.blue,
      thumbColor: Colors.blue,
    );
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          widget.controller.player.positionStream,
          widget.controller.player.bufferedPositionStream,
          widget.controller.player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
        stream: _positionDataStream,
        builder: (context, snapshot) {
          final positionData = snapshot.data;

          final duration = positionData?.duration ?? Duration.zero;
          final position = positionData?.position ?? Duration.zero;
          final bufferedPosition =
              positionData?.bufferedPosition ?? Duration.zero;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              //Slider to show the buffered data.
              SizedBox(
                height: 70,
                child: SliderTheme(
                  data: sliderThemeData.copyWith(
                    trackHeight: 4,
                    thumbShape: SliderComponentShape.noThumb,
                    trackShape: const _CustomSliderTrackShape(),
                    activeTrackColor: Colors.blue,
                  ),
                  child: ExcludeSemantics(
                    child: Slider(
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      value: min(bufferedPosition.inMilliseconds.toDouble(),
                          duration.inMilliseconds.toDouble()),
                      onChanged: (value) {
                        setState(() {
                          _dragValue = value;
                        });
                        if (widget.onChanged != null) {
                          widget.onChanged!(
                              Duration(milliseconds: value.round()));
                        }
                      },
                      onChangeEnd: (value) {
                        widget.controller
                            .seek(Duration(milliseconds: value.round()));
                        _dragValue = null;
                      },
                    ),
                  ),
                ),
              ),

              //Slider with the current position of the audio
              SizedBox(
                height: 70,
                child: SliderTheme(
                  data: sliderThemeData.copyWith(
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: min(_dragValue ?? position.inMilliseconds.toDouble(),
                        duration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      setState(() {
                        _dragValue = value;
                      });
                      if (widget.onChanged != null) {
                        widget
                            .onChanged!(Duration(milliseconds: value.round()));
                      }
                    },
                    onChangeEnd: (value) {
                      widget.controller
                          .seek(Duration(milliseconds: value.round()));

                      _dragValue = null;
                    },
                  ),
                ),
              ),

              //Righ timer
              Positioned(
                right: 24.0,
                bottom: 0.0,
                child: Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                          .firstMatch("$duration")
                          ?.group(1) ??
                      '$duration',
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                ),
              ),

              //Left timer
              Positioned(
                left: 24.0,
                bottom: 0.0,
                child: Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                          .firstMatch("$position")
                          ?.group(1) ??
                      '$position',
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                ),
              ),
            ],
          );
        });
  }
}

/// Uses the [RoundedRectSliderTrackShape] as a base class to paint the SliderTrackShape.
/// The only difference is that [RoundedRectSliderTrackShape] uses an additional height of 2 pixels
/// for the active track shape and with this class we don't.
class _CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  /// Create a slider track that draws two rectangles with rounded outer edges.
  const _CustomSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      additionalActiveTrackHeight: 0,
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
