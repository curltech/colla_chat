import 'package:flutter/material.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';

class AudioUtil {
  static Widget buildMusicVisualizer({
    Key? key,
    Color? color,
    double? width,
    double? height,
    double radius = 0,
    bool animate = false,
    List<BoxShadow>? shadows,
  }) {
    return MiniMusicVisualizer(
        key: key,
        color: color,
        width: width,
        height: height,
        radius: radius,
        animate: animate,
        shadows: shadows);
  }
}
