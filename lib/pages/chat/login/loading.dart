import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const List<String> darkBackgroudImages = [
  'assets/images/bg/login-bg-wd-1.jpg',
  'assets/images/bg/login-bg-wd-2.jpg',
  'assets/images/bg/login-bg-wd-3.jpg',
  'assets/images/bg/login-bg-wd-4.jpg',
  'assets/images/bg/login-bg-wd-5.jpg',
  'assets/images/bg/login-bg-wd-6.jpg',
  'assets/images/bg/login-bg-wd-7.jpg',
  'assets/images/bg/login-bg-wd-8.jpg',
  'assets/images/bg/login-bg-wd-9.jpg',
  'assets/images/bg/login-bg-wd-10.jpg',
  'assets/images/bg/login-bg-wd-11.jpg',
];

const List<String> lightBackgroudImages = [
  'assets/images/bg/login-bg-wl-1.jpg',
  'assets/images/bg/login-bg-wl-2.jpg',
  'assets/images/bg/login-bg-wl-3.jpg',
  'assets/images/bg/login-bg-wl-4.jpg',
  'assets/images/bg/login-bg-wl-5.jpg',
  'assets/images/bg/login-bg-wl-6.jpg',
  'assets/images/bg/login-bg-wl-7.jpg',
  'assets/images/bg/login-bg-wl-8.jpg',
  'assets/images/bg/login-bg-wl-9.jpg',
  'assets/images/bg/login-bg-wl-10.jpg',
  'assets/images/bg/login-bg-wl-11.jpg',
];

class Loading extends StatefulWidget {
  final String title;
  final bool autoPlay;
  final lightChildren = <Widget>[];
  final darkChildren = <Widget>[];
  final PageController controller = PageController();
  int currentIndex = 0;
  final animateDuration = const Duration(milliseconds: 500);

  Loading({Key? key, required this.title, this.autoPlay = true})
      : super(key: key) {
    for (int i = 0; i < lightBackgroudImages.length; ++i) {
      var image = Image.asset(
        lightBackgroudImages[i],
        fit: BoxFit.cover,
      );
      lightChildren.add(image);
    }
    for (int i = 0; i < darkBackgroudImages.length; ++i) {
      var image = Image.asset(
        darkBackgroudImages[i],
        fit: BoxFit.cover,
      );
      darkChildren.add(image);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _LoadingState();
  }
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();
    int count = lightBackgroudImages.length;
    if (appDataProvider.brightness == Brightness.dark.name) {
      count = darkBackgroudImages.length;
    }

    if (widget.autoPlay) {
      bool positive = true;
      Future.doWhile(() async {
        if (widget.currentIndex >= count - 1) {
          positive = false;
        }
        if (widget.currentIndex == 0) {
          positive = true;
        }
        try {
          if (positive) {
            widget.controller.nextPage(
                duration: widget.animateDuration, curve: Curves.easeInOut);
          } else {
            widget.controller.previousPage(
                duration: widget.animateDuration, curve: Curves.easeInOut);
          }
        } catch (e) {
          logger.e(e);
        }
        await Future.delayed(const Duration(seconds: 60));
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    AppDataProvider appDataProvider = Provider.of<AppDataProvider>(context);
    if (appDataProvider.brightness == Brightness.light.name) {
      children = widget.lightChildren;
    }
    if (appDataProvider.brightness == Brightness.dark.name) {
      children = widget.darkChildren;
    }
    return PageView(
      controller: widget.controller,
      onPageChanged: (int index) {
        widget.currentIndex = index;
      },
      children: children,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

var loadingWidget = Loading(title: '');
