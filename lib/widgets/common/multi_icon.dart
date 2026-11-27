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

class AnimateMultiIconController with ChangeNotifier {
  final List<Widget> icons;
  final Duration duration;
  int index = 0;
  bool playState = false;

  AnimateMultiIconController(this.icons,
      {this.duration = const Duration(milliseconds: 150)});

  void togglePlay() {
    if (playState) {
      playState = false;
      return;
    }
    playState = true;
    Future.doWhile(() async {
      await Future.delayed(duration, () {
        index++;
        if (index >= icons.length) {
          index = 0;
        }
        notifyListeners();
      });

      return playState;
    });
  }
}

class AnimateMultiIcon extends StatefulWidget {
  final AnimateMultiIconController animateMultiIconController;

  const AnimateMultiIcon({
    super.key,
    required this.animateMultiIconController,
  });

  @override
  State<StatefulWidget> createState() {
    return _AnimateMultiIconStat();
  }
}

class _AnimateMultiIconStat extends State<AnimateMultiIcon> {
  @override
  initState() {
    super.initState();
    widget.animateMultiIconController.addListener(_update);
  }

  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.animateMultiIconController
        .icons[widget.animateMultiIconController.index];
  }

  @override
  void dispose() {
    widget.animateMultiIconController.removeListener(_update);
    super.dispose();
  }
}
