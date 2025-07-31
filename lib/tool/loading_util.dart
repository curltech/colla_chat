import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LoadingUtil {
  static Widget buildLoadingIndicator({double? width, double? height}) {
    Widget loadingWidget = LoadingIndicator(
      indicatorType: Indicator.ballRotateChase,
      colors: [
        myself.primary,
      ],
    );
    return SizedBox(
        height: height ?? 128,
        width: width ?? 128,
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
              SizedBox(
                  height: height ?? 64,
                  width: width ?? 64,
                  child: loadingWidget),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                  child: AutoSizeText(
                      AppLocalizations.t("Loading, please waiting...")))
            ])));
  }

  static Widget buildLoadingAnimation({double? size}) {
    return SizedBox(
        height: size ?? 196,
        width: size ?? 196,
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
              LoadingAnimationWidget.discreteCircle(
                  color: myself.primary, size: size ?? 100),
              const SizedBox(
                height: 10,
              ),
              AutoSizeText(AppLocalizations.t("Loading, please waiting..."))
            ])));
  }

  // static Widget buildCircularLoadingWidget() {
  //   return Center(
  //       child: Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       CircularProgressIndicator(
  //           semanticsLabel: AppLocalizations.t("Loading, please waiting..."),
  //           color: myself.primary,
  //           backgroundColor: myself.secondary),
  //       const SizedBox(
  //         height: 10,
  //       ),
  //       Expanded(
  //           child: AutoSizeText(
  //               AppLocalizations.t("Loading, please waiting..."))),
  //     ],
  //   ));
  // }

  static LinearProgressIndicator buildLinearProgressIndicator() {
    return LinearProgressIndicator(
        minHeight: 1.0,
        color: myself.primary,
        backgroundColor: myself.secondary);
  }

  static RefreshIndicator buildRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      semanticsLabel: AppLocalizations.t("Loading, please waiting..."),
      child: child,
    );
  }

  static CircularPercentIndicator buildCircularPercentIndicator({
    Key? key,
    double percent = 0.0,
    double lineWidth = 5.0,
    double startAngle = 0.0,
    required double radius,
    Color fillColor = Colors.transparent,
    Color backgroundColor = const Color(0xFFB8C7CB),
    Color? progressColor,
    double backgroundWidth = -1,
    LinearGradient? linearGradient,
    bool animation = false,
    int animationDuration = 500,
    Widget? header,
    Widget? footer,
    Widget? center,
    bool addAutomaticKeepAlive = true,
    CircularStrokeCap circularStrokeCap = CircularStrokeCap.butt,
    Color? arcBackgroundColor,
    ArcType? arcType,
    bool animateFromLastPercent = false,
    bool reverse = false,
    Curve curve = Curves.linear,
    MaskFilter? maskFilter,
    bool restartAnimation = false,
    void Function()? onAnimationEnd,
    Widget? widgetIndicator,
    bool rotateLinearGradient = false,
  }) {
    return CircularPercentIndicator(
      key: key,
      percent: percent,
      lineWidth: lineWidth,
      startAngle: startAngle,
      radius: radius,
      fillColor: fillColor,
      backgroundColor: backgroundColor,
      progressColor: progressColor,
      backgroundWidth: backgroundWidth,
      linearGradient: linearGradient,
      animation: animation,
      animationDuration: animationDuration,
      header: header,
      footer: footer,
      center: center,
      addAutomaticKeepAlive: addAutomaticKeepAlive,
      circularStrokeCap: circularStrokeCap,
      arcBackgroundColor: arcBackgroundColor,
      arcType: arcType,
      animateFromLastPercent: animateFromLastPercent,
      reverse: reverse,
      curve: curve,
      maskFilter: maskFilter,
      restartAnimation: restartAnimation,
      onAnimationEnd: onAnimationEnd,
      widgetIndicator: widgetIndicator,
      rotateLinearGradient: rotateLinearGradient,
    );
  }

  static LinearPercentIndicator buildLinearPercentIndicator({
    Key? key,
    Color fillColor = Colors.transparent,
    double percent = 0.0,
    double lineHeight = 5.0,
    double? width,
    Color? backgroundColor,
    LinearGradient? linearGradientBackgroundColor,
    LinearGradient? linearGradient,
    Color? progressColor,
    bool animation = false,
    int animationDuration = 500,
    bool animateFromLastPercent = false,
    bool isRTL = false,
    Widget? leading,
    Widget? trailing,
    Widget? center,
    bool addAutomaticKeepAlive = true,
    Radius? barRadius,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10.0),
    MainAxisAlignment alignment = MainAxisAlignment.start,
    MaskFilter? maskFilter,
    bool clipLinearGradient = false,
    Curve curve = Curves.linear,
    bool restartAnimation = false,
    void Function()? onAnimationEnd,
    Widget? widgetIndicator,
  }) {
    return LinearPercentIndicator(
      key: key,
      fillColor: fillColor,
      percent: percent,
      lineHeight: lineHeight,
      width: width,
      backgroundColor: backgroundColor,
      linearGradientBackgroundColor: linearGradientBackgroundColor,
      linearGradient: linearGradient,
      progressColor: progressColor,
      animation: animation,
      animationDuration: animationDuration,
      animateFromLastPercent: animateFromLastPercent,
      isRTL: isRTL,
      leading: leading,
      trailing: trailing,
      center: center,
      addAutomaticKeepAlive: addAutomaticKeepAlive,
      barRadius: barRadius,
      padding: padding,
      alignment: alignment,
      maskFilter: maskFilter,
      clipLinearGradient: clipLinearGradient,
      curve: curve,
      restartAnimation: restartAnimation,
      onAnimationEnd: onAnimationEnd,
      widgetIndicator: widgetIndicator,
    );
  }
}

class TraceUtil {
  DateTime start(String msg) {
    DateTime t = DateTime.now().toUtc();
    logger.i('$msg, trace start:${t.toIso8601String()}');
    return t;
  }

  Duration end(DateTime start, String msg) {
    DateTime t = DateTime.now().toUtc();
    Duration diff = t.difference(start);
    logger.i('$msg, trace end:${t.toIso8601String()}, interval $diff');
    return diff;
  }
}

class CollectUtil {
  ///判断List是否为空
  static bool listNoEmpty(List? list) {
    if (list == null) return false;

    if (list.isEmpty) return false;

    return true;
  }
}

class StandardMessageCodecUtil {
  static Uint8List encode(Object o) {
    final ByteData? data = const StandardMessageCodec().encodeMessage(o);
    return data!.buffer.asUint8List();
  }

  static Uint8List decode(List<int> raw) {
    var data = Uint8List.fromList(raw);
    final dynamic o =
        const StandardMessageCodec().decodeMessage(ByteData.view(data.buffer));

    return o;
  }
}
