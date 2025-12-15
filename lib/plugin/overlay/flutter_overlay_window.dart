import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/overlay/flutter_floating_widget.dart';
import 'package:colla_chat/plugin/overlay/mobile_system_alert_window.dart';
import 'package:colla_chat/plugin/overlay/overlay_notification.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:system_alert_window/system_alert_window.dart';

class FlutterOverlayWindowWidget extends StatelessWidget with TileDataMixin {
  FlutterOverlayWindowWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'overlay_window';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Overlay window';

  final FlutterOverlayWindow flutterOverlayWindow =
      FlutterOverlayWindow(disabled: Text('测试版'));

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      withLeading: true,
      title: title,
      rightWidgets: [
        IconButton(
            onPressed: () {
              flutterOverlayWindow.set(OverlayNotification(
                key: UniqueKey(),
                description: AutoSizeText('Text'),
                onCloseButtonPressed:
                    (OverlayNotification overlayNotification) {
                  flutterOverlayWindow.close();
                },
                onDismiss: (OverlayNotification overlayNotification) {
                  flutterOverlayWindow.close();
                },
                onProgressFinished: (OverlayNotification overlayNotification) {
                  flutterOverlayWindow.close();
                },
                onNotificationPressed:
                    (OverlayNotification overlayNotification) {
                  flutterOverlayWindow.close();
                },
              ));
              flutterOverlayWindow.show(context);
            },
            icon: Icon(Icons.folder_open)),
        IconButton(
            onPressed: () {
              flutterOverlayWindow.close();
            },
            icon: Icon(Icons.folder)),
      ],
      child:
          flutterOverlayWindow, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class FlutterOverlayWindow extends StatelessWidget {
  final Widget disabled;

  FlutterOverlayWindow({super.key, required this.disabled});

  late final MobileSystemAlertHome mobileSystemAlertHome =
      MobileSystemAlertHome(disabled: disabled);

  late final FlutterFloatingHome flutterFloatingHome =
      FlutterFloatingHome(disabled: disabled);
  final Rx<String?> floatingKey = Rx<String?>(null);

  void show(BuildContext context) {
    if (platformParams.mobile) {
      mobileSystemAlertHome.showOverlay();
    } else {
      floatingKey.value ??= flutterFloatingHome.flutterFloatingController
          .createFloating(flutterFloatingOverlay);
      flutterFloatingHome.flutterFloatingController.open(context);
      flutterFloatingHome.flutterFloatingController.show();
    }
  }

  void close({SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT}) {
    if (platformParams.mobile) {
      mobileSystemAlertHome.closeOverlay();
    } else {
      flutterFloatingHome.flutterFloatingController.close();
      floatingKey.value = null;
    }
  }

  void set(Widget enabled) {
    if (platformParams.desktop) {
      flutterFloatingOverlay.enabled.value = enabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return platformParams.mobile ? mobileSystemAlertHome : flutterFloatingHome;
  }
}
