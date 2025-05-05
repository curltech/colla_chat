import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:flutter_floating/floating_icon.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/assist/slide_stop_type.dart';
import 'package:flutter_floating/floating/assist/Point.dart';
import 'package:get/get.dart';

class FlutterFloatingController {
  final FloatingManager floatingManager = FloatingManager();
  final Rx<String?> current = Rx<String?>(null);

  String createFloating(
    Widget child, {
    FloatingSlideType slideType = FloatingSlideType.onRightAndBottom,
    double? top,
    double? left,
    double? right,
    double? bottom,
    Point<double>? point,
    double moveOpacity = 0.3,
    bool isPosCache = true,
    bool isShowLog = true,
    bool isSnapToEdge = true,
    bool isStartScroll = true,
    double slideTopHeight = 0,
    double slideBottomHeight = 0,
    double snapToEdgeSpace = 0,
    SlideStopType slideStopType = SlideStopType.slideStopAutoType,
  }) {
    String key = UniqueKey().toString();
    floatingManager.createFloating(
        key,
        Floating(
          child,
          slideType: slideType,
          top: top,
          left: left,
          right: right,
          bottom: bottom,
          point: point,
          moveOpacity: moveOpacity,
          isPosCache: isPosCache,
          isShowLog: isShowLog,
          isSnapToEdge: isSnapToEdge,
          isStartScroll: isStartScroll,
          slideTopHeight: slideTopHeight,
          slideBottomHeight: slideBottomHeight,
          snapToEdgeSpace: snapToEdgeSpace,
          slideStopType: slideStopType,
        ));
    current.value = key;

    return key;
  }

  open(BuildContext context, {String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    Floating floating = floatingManager.getFloating(key);

    floating.open(context);
  }

  showFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    Floating floating = floatingManager.getFloating(key);

    floating.showFloating();
  }

  isShowing({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    Floating floating = floatingManager.getFloating(key);

    return floating.isShowing;
  }

  hideFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    Floating floating = floatingManager.getFloating(key);

    floating.hideFloating();
  }

  getFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    return floatingManager.getFloating(key);
  }

  closeFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    floatingManager.closeFloating(key);
  }

  closeAllFloating() {
    floatingManager.closeAllFloating();
  }
}

FlutterFloatingController flutterFloatingController =
    FlutterFloatingController();

/// 应用内的悬浮框，overlay实现方式
class FlutterFloatingWidget extends StatelessWidget with TileDataMixin {
  const FlutterFloatingWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'floating';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Floating';

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      withLeading: true,
      title: title,
      rightWidgets: [
        IconButton(
            onPressed: () {
              flutterFloatingController.createFloating(const FloatingIcon(),
                  slideType: FloatingSlideType.onRightAndBottom,
                  isShowLog: false,
                  isSnapToEdge: false,
                  isPosCache: true,
                  moveOpacity: 1,
                  left: 100,
                  bottom: 100,
                  slideBottomHeight: 100);
            },
            icon: Icon(Icons.add_photo_alternate)),
        IconButton(
            onPressed: () {
              flutterFloatingController.open(context);
            },
            icon: Icon(Icons.folder_open)),
        IconButton(
            onPressed: () {
              flutterFloatingController.closeFloating();
            },
            icon: Icon(Icons.folder)),
        IconButton(
            onPressed: () {
              flutterFloatingController.showFloating();
            },
            icon: Icon(Icons.show_chart)),
        IconButton(
            onPressed: () {
              flutterFloatingController.hideFloating();
            },
            icon: Icon(Icons.hide_image_outlined)),
      ],
      child: Center(
          child: Text(
              '测试版')), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
