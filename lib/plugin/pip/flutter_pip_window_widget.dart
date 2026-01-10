import 'package:colla_chat/plugin/overlay/overlay_notification.dart';
import 'package:colla_chat/plugin/pip/android_floating_pip_widget.dart';
import 'package:colla_chat/plugin/pip/inapp_pip_player_widget.dart';
import 'package:colla_chat/plugin/pip/mobile_fl_pip_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 画中画功能主页面，带有路由回调函数
class FlutterPipWindowWidget extends StatelessWidget with TileDataMixin {
  final FlutterPipWindow flutterPipWindow =
      FlutterPipWindow(disabled: Center(child: Text('测试版')));

  FlutterPipWindowWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'pip_window';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Pip window';

  Widget _buildEnabledWidget() {
    return OverlayNotification(
        key: UniqueKey(),
        autoDismiss: false,
        description: AutoSizeText(''));
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: title,
        rightWidgets: [
          IconButton(
              onPressed: () {
                flutterPipWindow.enable(enabled: _buildEnabledWidget());
              },
              icon: Icon(Icons.picture_in_picture)),
        ],
        child: flutterPipWindow);
  }
}

class FlutterPipWindow extends StatelessWidget {
  final Widget disabled;
  late final AndroidFloatingPipWidget? androidFloatingPipWidget;

  FlutterPipWindow({super.key, required this.disabled}) {
    if (platformParams.android) {
      androidFloatingPipWidget = buildAndroidFloatingPipWidget();
    } else {
      androidFloatingPipWidget = null;
    }
  }

  AndroidFloatingPipWidget buildAndroidFloatingPipWidget() {
    return AndroidFloatingPipWidget(disabled: Center(child: disabled));
  }

  void enable({Widget? enabled}) {
    if (platformParams.mobile) {
      mobileFlPipEnabledWidget.enable(enabled: enabled);
    } else if (platformParams.android) {
      androidFloatingPipWidget?.enable(enabled: enabled);
    } else {
      inAppPipPlayerWidget.enable(enabled: enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return androidFloatingPipWidget ?? disabled;
  }
}
