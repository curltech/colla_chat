import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';

class LoadingBackgroundImage {
  final List<String> darkBackgroudImages = [
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

  final List<String> lightBackgroudImages = [
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

  final lightChildren = <Widget>[];
  final darkChildren = <Widget>[];
  int currentIndex = 0;

  LoadingBackgroundImage() {
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
  final animateDuration = const Duration(milliseconds: 500);

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
    int count = loadingBackgroundImage.lightBackgroudImages.length;
    ///在initState中调用context出错
    // if (myself.getBrightness(context) == Brightness.dark) {
    //   count = loadingBackgroundImage.darkBackgroudImages.length;
    // }

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
