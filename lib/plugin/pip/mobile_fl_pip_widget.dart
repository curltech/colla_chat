import 'package:colla_chat/widgets/common/nil.dart';
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

/// FlPip实现移动的背景画中画功能
/// enabled是pip生效的时候显示的组件
class MobileFlPipEnabledWidget extends StatelessWidget {
  final MobileFlPipController mobileFlPipController = MobileFlPipController();
  final Rx<Widget> enabled = Rx<Widget>(nilBox);

  MobileFlPipEnabledWidget({super.key});

  void enable(
      {Widget? enabled,
      FlPiPAndroidConfig android = const FlPiPAndroidConfig(),
      FlPiPiOSConfig ios = const FlPiPiOSConfig()}) {
    if (enabled != null) {
      this.enabled.value = enabled;
    }
    mobileFlPipController.enable(android: android, ios: ios);
  }

  @override
  Widget build(BuildContext context) {
    return enabled.value;
  }
}

final MobileFlPipEnabledWidget mobileFlPipEnabledWidget =
    MobileFlPipEnabledWidget();
