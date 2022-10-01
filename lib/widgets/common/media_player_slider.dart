import 'dart:math';

import 'package:colla_chat/widgets/media/platform_media_widget.dart';
import 'package:flutter/material.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class MediaPlayerSliderUtil {}

class MediaPlayerSlider extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const MediaPlayerSlider({
    Key? key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  MediaPlayerSliderState createState() => MediaPlayerSliderState();
}

class MediaPlayerSliderState extends State<MediaPlayerSlider> {
  double? _dragValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    var sliderThemeData = PlatformMediaPlayerWidget.buildSliderTheme(context);
    return Row(
      children: [
        const SizedBox(
          width: 15,
        ),
        Text(
          getDurationText(widget.position),
          style: const TextStyle(),
        ),
        Expanded(
            child: SliderTheme(
          data: sliderThemeData,
          child: Slider(
            min: 0.0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
                widget.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(Duration(milliseconds: value.round()));
              }
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd!(Duration(milliseconds: value.round()));
              }
              _dragValue = null;
            },
          ),
        )),
        Text(
          getDurationText(widget.duration),
          style: const TextStyle(),
        ),
        const SizedBox(
          width: 15,
        )
      ],
    );
  }

  String getDurationText(Duration duration) {
    return RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
            .firstMatch("$duration")
            ?.group(1) ??
        '$duration';
  }

  Duration get _remaining => widget.duration - widget.position;
}
