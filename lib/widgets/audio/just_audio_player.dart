import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class JustAudioPlayer extends StatefulWidget {
  late final JustAudioPlayerController controller;
  final bool simple;

  JustAudioPlayer(
      {Key? key, JustAudioPlayerController? controller, this.simple = false})
      : super(key: key) {
    this.controller = controller ?? JustAudioPlayerController();
  }

  @override
  JustAudioPlayerState createState() => JustAudioPlayerState();
}

class JustAudioPlayerState extends State<JustAudioPlayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  Future<void> _init() async {
    widget.controller.addListener(_update);
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    widget.controller.player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      logger.e('A stream error occurred: $e');
    });
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    widget.controller.removeListener(_update);
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

  Widget _buildSimpleControllerPanel(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Display play/pause button and volume/speed sliders.
        JustAudioPlayerControllerPanel(widget.controller),
        _buildPlayerSlider(context),
      ],
    ));
  }

  Widget _buildPlayerSlider(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: widget.controller.positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: positionData?.duration ?? Duration.zero,
          position: positionData?.position ?? Duration.zero,
          bufferedPosition: positionData?.bufferedPosition ?? Duration.zero,
          onChangeEnd: widget.controller.seek,
        );
      },
    );
  }

  Widget _buildPlaylist(BuildContext context) {
    var playlist = widget.controller.playlist;
    var filenames = widget.controller.filenames;
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16.0, top: 16.0),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Ink(
                    child: InkWell(
                      child: const Icon(Icons.add),
                      onTap: () async {
                        List<String> filenames = await FileUtil.pickFiles();
                        for (var filename in filenames) {
                          await widget.controller.add(filename: filename);
                        }
                        // var filename =
                        //     'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
                        // widget.controller.player.setAudioSource(
                        //     AudioSource.uri(Uri.parse(filename)));
                      },
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 250.0,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (int initialIndex, int finalIndex) async {
                  if (finalIndex > playlist.length) {
                    finalIndex = playlist.length;
                  }
                  if (initialIndex < finalIndex) finalIndex--;
                  widget.controller.move(initialIndex, finalIndex);
                },
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  playlist.length,
                  (int index) {
                    return ListTile(
                      key: Key(index.toString()),
                      leading: Text(
                        index.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      title: Text(
                        filenames[index],
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    );
                  },
                  growable: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplexControllerPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlaylist(context),
        _buildPlayerSlider(context),
        // Display play/pause button and volume/speed sliders.
        JustAudioPlayerControllerPanel(widget.controller, simple: false),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.simple) {
      return _buildSimpleControllerPanel(context);
    }
    return _buildComplexControllerPanel(context);
  }
}

/// Displays the play/pause/stop button and volume/speed sliders.
class JustAudioPlayerControllerPanel extends StatelessWidget {
  final JustAudioPlayerController controller;
  final bool simple;

  const JustAudioPlayerControllerPanel(this.controller,
      {Key? key, this.simple = true})
      : super(key: key);

  void showSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    String suffix = '',
    required double value,
    required Stream<double> stream,
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

  @override
  Widget build(BuildContext context) {
    if (simple) {
      return _buildSimpleControlPanel();
    }
    return _buildComplexControlPanel(context);
  }

  Row _buildSimpleControlPanel() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<double>(
            stream: controller.player.volumeStream,
            builder: (context, snapshot) {
              var label = '${snapshot.data?.toStringAsFixed(1)}';
              return _buildVolumeButton(context, label: label);
            },
          ),
          StreamBuilder<PlayerState>(
              stream: controller.player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                List<Widget> widgets = [];
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  widgets.add(Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 24.0,
                    height: 24.0,
                    child: const CircularProgressIndicator(),
                  ));
                } else {
                  if (playing != true) {
                    widgets.add(Ink(
                        child: InkWell(
                      onTap: controller.play,
                      child: const Icon(Icons.play_arrow_rounded, size: 36),
                    )));
                  } else if (processingState != ProcessingState.completed) {
                    widgets.add(Ink(
                        child: InkWell(
                      onTap: controller.pause,
                      child: const Icon(Icons.pause, size: 36),
                    )));
                  } else {
                    widgets.add(Ink(
                        child: InkWell(
                      child: const Icon(Icons.replay, size: 36),
                      onTap: () => controller.seek(Duration.zero),
                    )));
                  }
                }
                return Row(
                  children: widgets,
                );
              }),
        ]);
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
          value: controller.getVolume(),
          stream: controller.player.volumeStream,
          onChanged: controller.setVolume,
        );
      },
    ));
  }

  Widget _buildSpeedButton(BuildContext context, {String? label}) {
    return Ink(
        child: InkWell(
      child: Row(children: [
        const Icon(Icons.speed_rounded, size: 24),
        Text(label ?? '')
      ]),
      onTap: () {
        showSliderDialog(
          context: context,
          title: "Adjust speed",
          divisions: 10,
          min: 0.5,
          max: 1.5,
          value: controller.getSpeed(),
          stream: controller.player.speedStream,
          onChanged: controller.setSpeed,
        );
      },
    ));
  }

  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<double>(
          stream: controller.player.volumeStream,
          builder: (context, snapshot) {
            var label = '${snapshot.data?.toStringAsFixed(1)}';
            return _buildVolumeButton(context, label: label);
          },
        ),
        const SizedBox(
          width: 50,
        ),
        _buildComplexPlayPanel(),
        const SizedBox(
          width: 50,
        ),
        StreamBuilder<double>(
          stream: controller.player.speedStream,
          builder: (context, snapshot) {
            var label = '${snapshot.data?.toStringAsFixed(1)}';
            return _buildSpeedButton(context, label: label);
          },
        ),
      ],
    );
  }

  StreamBuilder<PlayerState> _buildComplexPlayPanel() {
    return StreamBuilder<PlayerState>(
        stream: controller.player.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;
          final playing = playerState?.playing;
          List<Widget> widgets = [];
          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            widgets.add(Container(
              margin: const EdgeInsets.all(8.0),
              width: 24.0,
              height: 24.0,
              child: const CircularProgressIndicator(),
            ));
          } else {
            widgets.add(Ink(
                child: InkWell(
              onTap: controller.stop,
              child: const Icon(Icons.stop_rounded, size: 36),
            )));

            widgets.add(Ink(
                child: InkWell(
              onTap: controller.previous,
              child: const Icon(Icons.skip_previous_rounded, size: 36),
            )));
            if (playing != true) {
              widgets.add(Ink(
                  child: InkWell(
                onTap: controller.play,
                child: const Icon(Icons.play_arrow_rounded, size: 36),
              )));
            } else if (processingState != ProcessingState.completed) {
              widgets.add(Ink(
                  child: InkWell(
                onTap: controller.pause,
                child: const Icon(Icons.pause, size: 36),
              )));
            } else {
              widgets.add(Ink(
                  child: InkWell(
                child: const Icon(Icons.replay, size: 36),
                onTap: () => controller.seek(Duration.zero),
              )));
            }
            widgets.add(Ink(
                child: InkWell(
              onTap: controller.next,
              child: const Icon(Icons.skip_next_rounded, size: 36),
            )));
          }
          return Row(
            children: widgets,
          );
        });
  }
}

