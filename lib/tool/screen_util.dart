import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ScreenUtil {
  static double winWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double winHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double winTop(BuildContext context) {
    return MediaQuery.paddingOf(context).top;
  }

  static double winBottom(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }

  static double winLeft(BuildContext context) {
    return MediaQuery.paddingOf(context).left;
  }

  static double winRight(BuildContext context) {
    return MediaQuery.paddingOf(context).right;
  }

  static double winKeyHeight(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom;
  }

  static double statusBarHeight(BuildContext context) {
    return MediaQueryData.fromView(ui.window).padding.top;
  }

  static double navigationBarHeight(BuildContext context) {
    return kToolbarHeight;
  }

  static double topBarHeight(BuildContext context) {
    return kToolbarHeight + MediaQueryData.fromView(ui.window).padding.top;
  }
}
