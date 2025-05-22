import 'dart:async';
import 'dart:math';

import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 用floating实现android的画中画功能
class AndroidFloatingPipController {
  final floating = Floating();

  AndroidFloatingPipController();

  Future<bool> isAvailable() async {
    return await floating.isPipAvailable;
  }

  Future<void> toggle(PiPStatus state) async {
    if (await status == PiPStatus.enabled) {
      await disable();
    } else if (await status == PiPStatus.disabled) {
      await enable();
    }
  }

  Future<PiPStatus> get status async {
    return await floating.pipStatus;
  }

  Future<void> disable() async {
    return await floating.cancelOnLeavePiP();
  }

  /// isImmediate表示立即显示pip组件
  /// 反之表示应用进入后台的时候才显示pip组件
  Future<PiPStatus> enable(
      {Rational aspectRatio = const Rational.landscape(),
      Rectangle<int>? sourceRectHint,
      bool isImmediate = true}) async {
    EnableArguments arguments;
    if (isImmediate) {
      arguments = ImmediatePiP(
          aspectRatio: aspectRatio, sourceRectHint: sourceRectHint);
    } else {
      arguments =
          OnLeavePiP(aspectRatio: aspectRatio, sourceRectHint: sourceRectHint);
    }
    return await floating.enable(arguments);
  }
}

/// Floating实现android的背景画中画功能
/// enabled是pip生效的时候显示的组件
/// disabled是pip无效的时候显示的组件
class AndroidFloatingPipWidget extends StatelessWidget {
  final AndroidFloatingPipController androidFloatingPipController =
      AndroidFloatingPipController();
  final Widget disabled;
  final Rx<Widget> enabled = Rx<Widget>(Container());

  AndroidFloatingPipWidget({super.key, required this.disabled});

  enable(
      {Widget? enabled,
      Rational aspectRatio = const Rational.landscape(),
      Rectangle<int>? sourceRectHint,
      bool isImmediate = true}) {
    if (enabled != null) {
      this.enabled.value = enabled;
    }
    androidFloatingPipController.enable(
        aspectRatio: aspectRatio,
        sourceRectHint: sourceRectHint,
        isImmediate: isImmediate);
  }

  @override
  Widget build(BuildContext context) {
    return PiPSwitcher(
      childWhenDisabled: disabled,
      childWhenEnabled: Obx(() {
        return enabled.value;
      }),
    );
  }
}
