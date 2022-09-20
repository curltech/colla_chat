import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/widgets/audio/blue_fire_audio_player.dart';
import 'package:flutter/material.dart';

class BlueFireAudioPlayerWidget extends StatefulWidget {
  late final BlueFireAudioPlayerController controller;

  BlueFireAudioPlayerWidget({
    Key? key,
    BlueFireAudioPlayerController? controller,
  }) : super(key: key) {
    controller = controller ?? BlueFireAudioPlayerController();
  }

  @override
  State<StatefulWidget> createState() {
    return _BlueFireAudioPlayerWidgetState();
  }
}

class _BlueFireAudioPlayerWidgetState extends State<BlueFireAudioPlayerWidget> {
  AudioPlayer get player => widget.controller.player;

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('play_button'),
              onPressed:
                  widget.controller.state == PlayerState.playing ? null : _play,
              iconSize: 48.0,
              icon: const Icon(Icons.play_arrow),
              color: Colors.cyan,
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: widget.controller.state == PlayerState.playing
                  ? _pause
                  : null,
              iconSize: 48.0,
              icon: const Icon(Icons.pause),
              color: Colors.cyan,
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: widget.controller.state == PlayerState.playing ||
                      widget.controller.state == PlayerState.paused
                  ? _stop
                  : null,
              iconSize: 48.0,
              icon: const Icon(Icons.stop),
              color: Colors.cyan,
            ),
          ],
        ),
        Slider(
          onChanged: (v) async {
            final duration = await widget.controller.getDuration();
            if (duration == null) {
              return;
            }
            final position = v * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (widget.controller.position != null &&
                  widget.controller.duration != null &&
                  widget.controller.position!.inMilliseconds > 0 &&
                  widget.controller.position!.inMilliseconds <
                      widget.controller.duration!.inMilliseconds)
              ? widget.controller.position!.inMilliseconds /
                  widget.controller.duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          widget.controller.position != null
              ? '${widget.controller.position} / ${widget.controller.duration}'
              : widget.controller.duration != null
                  ? '${widget.controller.duration}'
                  : '',
          style: const TextStyle(fontSize: 16.0),
        ),
        Text('State: ${widget.controller.state.name}'),
      ],
    );
  }

  Future<void> _play() async {
    final position = widget.controller.position;
    if (position != null && position.inMilliseconds > 0) {
      await widget.controller.seek(position);
    }
    await widget.controller.resume();
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() {});
  }

  Future<void> _stop() async {
    await player.stop();
    setState(() {});
  }
}
