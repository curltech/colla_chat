import 'dart:math';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';

class LoadingBackgroundImage {
  final List<String> darkBackgroundImages = [
    'assets/images/bg/login-bg-wd-1.webp',
    'assets/images/bg/login-bg-wd-2.webp',
    'assets/images/bg/login-bg-wd-3.webp',
    'assets/images/bg/login-bg-wd-4.webp',
    'assets/images/bg/login-bg-wd-5.webp',
    'assets/images/bg/login-bg-wd-6.webp',
    'assets/images/bg/login-bg-wd-7.webp',
    'assets/images/bg/login-bg-wd-8.webp',
    'assets/images/bg/login-bg-wd-9.webp',
    'assets/images/bg/login-bg-wd-10.webp',
    'assets/images/bg/login-bg-wd-11.webp',
    'assets/images/bg/login-bg-wd-12.webp',
  ];

  final List<String> lightBackgroundImages = [
    'assets/images/bg/login-bg-wl-1.webp',
    'assets/images/bg/login-bg-wl-2.webp',
    'assets/images/bg/login-bg-wl-3.webp',
    'assets/images/bg/login-bg-wl-4.webp',
    'assets/images/bg/login-bg-wl-5.webp',
    'assets/images/bg/login-bg-wl-6.webp',
    'assets/images/bg/login-bg-wl-7.webp',
    'assets/images/bg/login-bg-wl-8.webp',
    'assets/images/bg/login-bg-wl-9.webp',
    'assets/images/bg/login-bg-wl-10.webp',
    'assets/images/bg/login-bg-wl-11.webp',
    'assets/images/bg/login-bg-wl-12.webp',
  ];

  final lightChildren = <Widget>[];
  final darkChildren = <Widget>[];
  int currentIndex = 0;

  LoadingBackgroundImage() {
    for (int i = 0; i < lightBackgroundImages.length; ++i) {
      var image = Image.asset(
        lightBackgroundImages[i],
        fit: BoxFit.cover,
      );
      lightChildren.add(image);
    }
    for (int i = 0; i < darkBackgroundImages.length; ++i) {
      var image = Image.asset(
        darkBackgroundImages[i],
        fit: BoxFit.cover,
      );
      darkChildren.add(image);
    }
  }

  Widget? currentBackgroundImage(BuildContext? context) {
    if (context == null) {
      return loadingBackgroundImage.lightChildren[currentIndex];
    }
    if (myself.getBrightness(context) == Brightness.light) {
      return loadingBackgroundImage.lightChildren[currentIndex];
    }
    if (myself.getBrightness(context) == Brightness.dark) {
      return loadingBackgroundImage.darkChildren[currentIndex];
    }

    return null;
  }
}

LoadingBackgroundImage loadingBackgroundImage = LoadingBackgroundImage();

class Loading extends StatefulWidget {
  final String title;
  final bool autoPlay;

  final SwiperController controller = SwiperController();

  Loading({Key? key, required this.title, this.autoPlay = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoadingState();
  }
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();
    myself.addListener(_update);
    int count = loadingBackgroundImage.lightBackgroundImages.length;

    ///在initState中调用context出错
    // if (myself.getBrightness(context) == Brightness.dark) {
    //   count = loadingBackgroundImage.darkBackgroudImages.length;
    // }
    var random = Random.secure();
    loadingBackgroundImage.currentIndex = random.nextInt(count);
    if (widget.autoPlay) {
      bool positive = true;
      Future.doWhile(() async {
        if (loadingBackgroundImage.currentIndex >= count - 1) {
          positive = false;
        }
        if (loadingBackgroundImage.currentIndex == 0) {
          positive = true;
        }
        try {
          if (positive) {
            widget.controller.next();
          } else {
            widget.controller.previous();
          }
        } catch (e) {
          logger.e(e);
        }
        await Future.delayed(const Duration(seconds: 60));
        return true;
      });
    }
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (myself.getBrightness(context) == Brightness.light) {
      children = loadingBackgroundImage.lightChildren;
    }
    if (myself.getBrightness(context) == Brightness.dark) {
      children = loadingBackgroundImage.darkChildren;
    }
    return Swiper(
      controller: widget.controller,
      onIndexChanged: (int index) {
        loadingBackgroundImage.currentIndex = index;
      },
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) {
        return children[index];
      },
      index: 0,
    );
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    super.dispose();
  }
}

var loadingWidget = Loading(title: '');
