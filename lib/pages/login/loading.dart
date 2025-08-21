import 'dart:async';
import 'dart:math';

import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class BackgroundImages {
  static const List<String> darkBackgroundImages = [
    'assets/image/bg/login-bg-wd-1.webp',
    'assets/image/bg/login-bg-wd-2.webp',
    'assets/image/bg/login-bg-wd-3.webp',
    'assets/image/bg/login-bg-wd-4.webp',
    'assets/image/bg/login-bg-wd-5.webp',
    'assets/image/bg/login-bg-wd-6.webp',
    'assets/image/bg/login-bg-wd-7.webp',
    'assets/image/bg/login-bg-wd-8.webp',
    'assets/image/bg/login-bg-wd-9.webp',
    'assets/image/bg/login-bg-wd-10.webp',
    'assets/image/bg/login-bg-wd-11.webp',
    'assets/image/bg/login-bg-wd-12.webp',
  ];

  static const List<String> lightBackgroundImages = [
    'assets/image/bg/login-bg-wl-1.webp',
    'assets/image/bg/login-bg-wl-2.webp',
    'assets/image/bg/login-bg-wl-3.webp',
    'assets/image/bg/login-bg-wl-4.webp',
    'assets/image/bg/login-bg-wl-5.webp',
    'assets/image/bg/login-bg-wl-6.webp',
    'assets/image/bg/login-bg-wl-7.webp',
    'assets/image/bg/login-bg-wl-8.webp',
    'assets/image/bg/login-bg-wl-9.webp',
    'assets/image/bg/login-bg-wl-10.webp',
    'assets/image/bg/login-bg-wl-11.webp',
    'assets/image/bg/login-bg-wl-12.webp',
  ];

  final lightChildren = <Widget>[];
  final darkChildren = <Widget>[];
  int currentIndex = 0;

  BackgroundImages() {
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
      return backgroundImages.lightChildren[currentIndex];
    }
    if (myself.getBrightness(context) == Brightness.light) {
      return backgroundImages.lightChildren[currentIndex];
    }
    if (myself.getBrightness(context) == Brightness.dark) {
      return backgroundImages.darkChildren[currentIndex];
    }

    return null;
  }
}

final BackgroundImages backgroundImages = BackgroundImages();

class Loading extends StatelessWidget {
  final bool autoPlay = true;

  final PlatformCarouselController controller = PlatformCarouselController(platformCarouselType : PlatformCarouselType.card,);

  Loading({super.key}) {
    init();
  }

  void init() {
    int count = BackgroundImages.lightBackgroundImages.length;

    ///在initState中调用context出错
    // if (myself.getBrightness(context) == Brightness.dark) {
    //   count = backgroundImages.darkBackgroundImages.length;
    // }
    if (autoPlay) {
      Timer.periodic(const Duration(seconds: 60), (timer) {
        var random = Random.secure();
        backgroundImages.currentIndex = random.nextInt(count);
        try {
          if (backgroundImages.currentIndex < count) {
            controller.move(backgroundImages.currentIndex);
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
        List<Widget> children = backgroundImages.lightChildren;
        if (myself.getBrightness(context) == Brightness.dark) {
          children = backgroundImages.darkChildren;
        }
        return PlatformCarouselWidget(
          height: appDataProvider.totalSize.height,
          controller: controller,
          onPageChanged: (index,
              {PlatformSwiperDirection? direction,
              int? oldIndex,
              CarouselPageChangedReason? reason}) {
            backgroundImages.currentIndex = index;
          },
          itemCount: children.length,
          itemBuilder: (BuildContext context, int index, {int? realIndex}) {
            return children[index];
          },
          initialPage: 0,
        );
      },
    );
  }
}

final Loading loadingWidget = Loading();
