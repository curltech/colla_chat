import 'package:colla_chat/widgets/common/nil.dart';
import 'package:fl_pip/fl_pip.dart';
import 'package:material_ui/material_ui.dart';

class MobileFlPipController {
  final FlPiP flPiP = FlPiP.instance;

  MobileFlPipController();

  Future<bool> isAvailable() async {
    return await flPiP.isAvailable;
  }

  Future<void> toggle(FlPiPAppState state) async {
    return await flPiP.toggle(state);
  }

  ValueNotifier<FlPiPStatusInfo?> get status {
    return flPiP.status;
  }

  Future<bool> dismiss() async {
    return await flPiP.dismiss();
  }

  /// 显示pip的画中画组件，mobileFlPipEnabledWidget
  Future<FlMultiEngineInfo> present({
    FlPiPAndroidOptions android = const FlPiPAndroidOptions.systemPip(
        aspectRatio: FlPiPAspectRatio.landscape()),
    FlPiPIOSOptions ios = const FlPiPIOSOptions(),
    FlPiPHarmonyOSOptions harmonyOS = const FlPiPHarmonyOSOptions.systemPip(),
  }) async {
    return await flPiP.present(
        android: android, ios: ios, harmonyOS: harmonyOS, name: 'pipMain');
  }
}

/// FlPip实现移动的背景画中画功能
/// enabled是pip生效的时候显示的组件
class MobileFlPipEnabledWidget extends StatelessWidget {
  final MobileFlPipController mobileFlPipController = MobileFlPipController();
  final ValueNotifier<Widget> enabled = ValueNotifier<Widget>(nilBox);

  MobileFlPipEnabledWidget({super.key});

  void present({
    Widget? enabled,
    FlPiPAndroidOptions android = const FlPiPAndroidOptions.systemPip(
        aspectRatio: FlPiPAspectRatio.landscape()),
    FlPiPIOSOptions ios = const FlPiPIOSOptions(),
    FlPiPHarmonyOSOptions harmonyOS = const FlPiPHarmonyOSOptions.systemPip(),
  }) {
    if (enabled != null) {
      this.enabled.value = enabled;
    }
    mobileFlPipController.present(
        android: android, ios: ios, harmonyOS: harmonyOS);
  }

  @override
  Widget build(BuildContext context) {
    return enabled.value;
  }
}

final MobileFlPipEnabledWidget mobileFlPipEnabledWidget =
    MobileFlPipEnabledWidget();
