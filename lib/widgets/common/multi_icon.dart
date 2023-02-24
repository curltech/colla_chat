import 'package:flutter/material.dart';

class StackMultiIcon extends StatelessWidget {
  final List<Widget> icons;

  const StackMultiIcon({super.key, required this.icons});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: icons,
    );
  }
}

class AnimateMultiIcon extends StatefulWidget {
  final List<Widget> icons;
  final Duration duration;

  const AnimateMultiIcon(
      {super.key,
      required this.icons,
      this.duration = const Duration(milliseconds: 100)});

  @override
  State<StatefulWidget> createState() {
    return _AnimateMultiIconStat();
  }
}

class _AnimateMultiIconStat extends State<AnimateMultiIcon> {
  int index = 0;

  @override
  initState() {
    super.initState();
    Future.doWhile(() async {
      if (index >= widget.icons.length - 1) {
        index = 0;
      }
      await Future.delayed(widget.duration, () {
        index++;
        setState(() {});
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.icons[index];
  }
}
