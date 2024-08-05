import 'dart:async';
import 'dart:math';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class LoadingBackgroundImage {
  static const List<String> darkBackgroundImages = [
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

  static const List<String> lightBackgroundImages = [
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
    FlutterNativeSplash.remove();
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

final LoadingBackgroundImage loadingBackgroundImage = LoadingBackgroundImage();

class Loading extends StatelessWidget {
  final bool autoPlay = true;

  final SwiperController swiperController = SwiperController();

  Loading({super.key}) {
    init();
  }

  void init() {
    int count = LoadingBackgroundImage.lightBackgroundImages.length;

    ///在initState中调用context出错
    // if (myself.getBrightness(context) == Brightness.dark) {
    //   count = loadingBackgroundImage.darkBackgroudImages.length;
    // }
    if (autoPlay) {
      Timer.periodic(const Duration(seconds: 60), (timer) {
        var random = Random.secure();
        loadingBackgroundImage.currentIndex = random.nextInt(count);
        try {
          if (loadingBackgroundImage.currentIndex < count) {
            swiperController.move(loadingBackgroundImage.currentIndex);
          }
        } catch (e) {
          logger.e(e.toString());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: myself,
      builder: (BuildContext context, Widget? child) {
        List<Widget> children = loadingBackgroundImage.lightChildren;
        if (myself.getBrightness(context) == Brightness.dark) {
          children = loadingBackgroundImage.darkChildren;
        }
        return Swiper(
          controller: swiperController,
          onIndexChanged: (int index) {
            loadingBackgroundImage.currentIndex = index;
          },
          itemCount: children.length,
          itemBuilder: (BuildContext context, int index) {
            return children[index];
          },
          index: 0,
        );
      },
    );
  }
}

final Loading loadingWidget = Loading();
