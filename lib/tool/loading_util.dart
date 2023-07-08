import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoadingUtil {
  static Widget buildLoadingIndicator() {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(
          height: 80,
          width: 80,
          child: LoadingIndicator(
            indicatorType: Indicator.ballRotateChase,
          )),
      const SizedBox(
        height: 10,
      ),
      CommonAutoSizeText(AppLocalizations.t("Loading, please waiting..."))
    ]));
  }

  static Widget buildLoadingAnimation() {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      LoadingAnimationWidget.discreteCircle(color: myself.primary, size: 200),
      const SizedBox(
        height: 10,
      ),
      CommonAutoSizeText(AppLocalizations.t("Loading, please waiting..."))
    ]));
  }

  static Widget buildCircularLoadingWidget() {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
            semanticsLabel: AppLocalizations.t("Loading, please waiting..."),
            color: myself.primary,
            backgroundColor: myself.secondary),
        const SizedBox(
          height: 10,
        ),
        CommonAutoSizeText(AppLocalizations.t("Loading, please waiting...")),
      ],
    ));
  }

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
