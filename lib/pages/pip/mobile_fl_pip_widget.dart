import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MobileFlPipController {
  final FlPiP flPiP = FlPiP();

  MobileFlPipController();

  Future<bool> isAvailable() async {
    return await flPiP.isAvailable;
  }

  Future<void> toggle(AppState state) async {
    return await flPiP.toggle(state);
  }

  ValueNotifier<PiPStatusInfo?> get status {
    return flPiP.status;
  }

  Future<bool> disable() async {
    return await flPiP.disable();
  }

  /// 显示pip的画中画组件，mobileFlPipEnabledWidget
  Future<bool> enable(
      {FlPiPAndroidConfig android = const FlPiPAndroidConfig(),
      FlPiPiOSConfig ios = const FlPiPiOSConfig()}) async {
    return await flPiP.enable(android: android, ios: ios);
  }
}

final MobileFlPipController mobileFlPipController = MobileFlPipController();

/// FlPip实现移动的背景画中画功能
/// enabled是pip生效的时候显示的组件
class MobileFlPipEnabledWidget extends StatelessWidget {
  final Rx<Widget> enabled = Rx<Widget>(Container());

  MobileFlPipEnabledWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return enabled.value;
    });
  }
}

final MobileFlPipEnabledWidget mobileFlPipEnabledWidget =
    MobileFlPipEnabledWidget();
