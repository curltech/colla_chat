import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class PlatformBreakpoint extends Breakpoint {
  const PlatformBreakpoint({this.begin, this.end});

  final double? begin;

  final double? end;

  @override
  bool isActive(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    ///竖屏
    if (end != null) {
      return width < end! || width <= height;
    }

    ///中等横屏
    if (begin != null && end != null) {
      return width > begin! && width < end! && width > height;
    }

    ///大横屏
    if (begin != null) {
      return width > begin! && width > height;
    }

    return false;
  }
}
