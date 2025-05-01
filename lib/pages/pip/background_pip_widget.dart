import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:fl_pip/fl_pip.dart';

class PipController {
  Widget backgroundPipView = Container();
  Widget backgroundPipWidget = Container();

  PipController();

  Future<bool> isAvailable() async {
    return await FlPiP().isAvailable;
  }

  Future<void> toggle(AppState state) async {
    return await FlPiP().toggle(state);
  }

  ValueNotifier<PiPStatusInfo?> get status {
    return FlPiP().status;
  }

  Future<bool> disable() async {
    return await FlPiP().disable();
  }

  Future<bool> enable(
      {FlPiPAndroidConfig android = const FlPiPAndroidConfig(),
      FlPiPiOSConfig ios = const FlPiPiOSConfig()}) async {
    return await FlPiP().enable(android: android, ios: ios);
  }
}

final PipController pipController = PipController();

/// 后台画中画功能
class BackgroundPipWidget extends StatelessWidget with TileDataMixin {
  BackgroundPipWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'background_pip';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Background pip';

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true, child: pipController.backgroundPipWidget);
  }
}

class BackgroundPipView extends StatelessWidget {
  const BackgroundPipView({super.key});

  @override
  Widget build(BuildContext context) {
    return pipController.backgroundPipView;
  }
}
