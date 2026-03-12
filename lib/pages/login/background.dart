import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kmeans_dominant_colors/kmeans_dominant_colors.dart';
import 'package:image/image.dart' as img;

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
  final lightColors = <Color>[];
  final darkColors = <Color>[];
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
    // extract();
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

  Future<void> extract() async {
    for (int i = 0; i < lightBackgroundImages.length; ++i) {
      var color = await extractColors(lightBackgroundImages[i]);
      lightColors.add(color);
    }
    for (int i = 0; i < darkBackgroundImages.length; ++i) {
      var color = await extractColors(darkBackgroundImages[i]);
      darkColors.add(color);
    }
  }

  Future<Color> extractColors(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final color = await compute((Uint8List bytes) {
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      final List<Color> colors =
          KMeansDominantColors.extract(image: image, count: 1);

      return colors[0];
    }, bytes);

    return color;
  }
}

final BackgroundImages backgroundImages = BackgroundImages();

class BackgroundWidget extends StatelessWidget {
  final bool autoPlay = true;

  final PlatformCarouselController controller = PlatformCarouselController(
    platformCarouselType: PlatformCarouselType.card,
  );

  BackgroundWidget({super.key});

  void _init() {
    int count = BackgroundImages.lightBackgroundImages.length;
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
          autoPlay: autoPlay,
          onPageChanged: (index,
              {PlatformSwiperDirection? direction,
              int? oldIndex,
              CarouselPageChangedReason? reason}) {
            backgroundImages.currentIndex = index;
            // Color color = backgroundImages.lightColors[index];
            // if (myself.getBrightness(context) == Brightness.dark) {
            //   color = backgroundImages.darkColors[index];
            // }
            // myself.primaryColor = color;
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

final BackgroundWidget backgroundWidget = BackgroundWidget();
