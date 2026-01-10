import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtil {
  static void show({
    required BuildContext context,
    AlignmentGeometry? alignment = Alignment.topRight,
    Duration? autoCloseDuration = const Duration(seconds: 5),
    OverlayState? overlayState,
    Widget Function(BuildContext, Animation<double>, Alignment, Widget)?
        animationBuilder,
    required ToastificationType type,
    ToastificationStyle? style = ToastificationStyle.flat,
    required String title,
    Duration? animationDuration = const Duration(milliseconds: 300),
    required String description,
    required Widget icon,
    Color? primaryColor,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    TextDirection? direction,
    bool? showProgressBar,
    ProgressIndicatorThemeData? progressBarTheme,
    CloseButtonShowType? closeButtonShowType,
    bool? closeOnClick,
    bool? dragToClose,
    bool? pauseOnHover,
  }) {
    primaryColor ??= myself.primary;
    backgroundColor ??= Colors.white;
    foregroundColor ??= Colors.black;
    padding ??= const EdgeInsets.symmetric(horizontal: 10, vertical: 15);
    margin ??= const EdgeInsets.symmetric(horizontal: 10, vertical: 10);
    borderRadius ??= BorderRadius.circular(12);
    boxShadow ??= [
      BoxShadow(
        color: myself.primary,
        blurRadius: 16,
        offset: const Offset(0, 16),
        spreadRadius: 0,
      )
    ];
    showProgressBar ??= true;
    closeButtonShowType ??= CloseButtonShowType.onHover;
    closeOnClick ??= false;
    pauseOnHover ??= true;
    dragToClose ??= true;
    Toastification().show(
      context: context,
      alignment: alignment,
      autoCloseDuration: autoCloseDuration,
      overlayState: overlayState,
      animationBuilder: animationBuilder,
      type: type,
      style: style,
      title: Text(title),
      animationDuration: animationDuration,
      description: Text(description),
      icon: icon,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      direction: direction,
      showProgressBar: showProgressBar,
      progressBarTheme: progressBarTheme,
      closeButtonShowType: closeButtonShowType,
      closeOnClick: closeOnClick,
      dragToClose: dragToClose,
      pauseOnHover: pauseOnHover,
    );
  }
}
