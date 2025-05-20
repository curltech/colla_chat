import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/overlay/flutter_floating_widget.dart';
import 'package:colla_chat/plugin/overlay/mobile_system_alert_window.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:flutter_floating/floating/assist/Point.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/assist/slide_stop_type.dart';

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
              mobileSystemAlertOverlay.enabled.value = Icon(
                Icons.access_alarm_outlined,
                color: myself.primary,
              );
              flutterOverlayWindow.showOverlay(context);
            },
            icon: Icon(Icons.folder_open)),
        IconButton(
            onPressed: () {
              flutterOverlayWindow.closeOverlay();
            },
            icon: Icon(Icons.folder)),
      ],
      child:
          flutterOverlayWindow, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MobileOverlayConfig {
  final SystemWindowGravity gravity;
  final int? width;
  final int? height;
  final String notificationTitle;

  final String notificationBody;

  final SystemWindowPrefMode prefMode;

  final List<SystemWindowFlags>? layoutParamFlags;

  const MobileOverlayConfig(
      {this.height,
      this.width,
      this.notificationTitle = "CollaChat",
      this.notificationBody = "CollaChat",
      this.prefMode = SystemWindowPrefMode.DEFAULT,
      this.layoutParamFlags,
      this.gravity = SystemWindowGravity.CENTER});
}

class DesktopConfig {
  final FloatingSlideType slideType;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Point<double>? point;
  final double moveOpacity;

  final bool isPosCache;

  final bool isShowLog;

  final bool isSnapToEdge;

  final bool isStartScroll;

  final double slideTopHeight;

  final double slideBottomHeight;

  final double snapToEdgeSpace;

  final SlideStopType slideStopType;

  const DesktopConfig(
      {this.slideType = FloatingSlideType.onRightAndBottom,
      this.moveOpacity = 0.3,
      this.isPosCache = true,
      this.isShowLog = true,
      this.isSnapToEdge = true,
      this.isStartScroll = true,
      this.slideTopHeight = 0,
      this.slideBottomHeight = 0,
      this.snapToEdgeSpace = 0,
      this.slideStopType = SlideStopType.slideStopAutoType,
      this.top,
      this.left,
      this.right,
      this.bottom,
      this.point});
}

class FlutterOverlayWindow extends StatelessWidget {
  final Widget disabled;

  FlutterOverlayWindow({super.key, required this.disabled});

  late final MobileSystemAlertHome mobileSystemAlertHome =
      MobileSystemAlertHome(disabled: disabled);

  late final FlutterFloatingHome flutterFloatingHome =
      FlutterFloatingHome(disabled: disabled);
  String? floatingKey;

  showOverlay(BuildContext context,
      {MobileOverlayConfig mobileOverlayConfig = const MobileOverlayConfig(),
      DesktopConfig desktopConfig = const DesktopConfig()}) {
    if (platformParams.mobile) {
      mobileSystemAlertHome.showOverlay(
          gravity: mobileOverlayConfig.gravity,
          width: mobileOverlayConfig.width,
          height: mobileOverlayConfig.height,
          notificationTitle: mobileOverlayConfig.notificationTitle,
          notificationBody: mobileOverlayConfig.notificationBody,
          prefMode: mobileOverlayConfig.prefMode,
          layoutParamFlags: mobileOverlayConfig.layoutParamFlags);
    } else {
      floatingKey ??= flutterFloatingHome.flutterFloatingController
          .createFloating(flutterFloatingOverlay,
              slideType: desktopConfig.slideType,
              isShowLog: desktopConfig.isShowLog,
              isSnapToEdge: desktopConfig.isSnapToEdge,
              isPosCache: desktopConfig.isPosCache,
              moveOpacity: desktopConfig.moveOpacity,
              left: desktopConfig.left,
              right: desktopConfig.right,
              top: desktopConfig.top,
              bottom: desktopConfig.bottom,
              point: desktopConfig.point,
              isStartScroll: desktopConfig.isStartScroll,
              slideTopHeight: desktopConfig.slideTopHeight,
              snapToEdgeSpace: desktopConfig.snapToEdgeSpace,
              slideStopType: desktopConfig.slideStopType,
              slideBottomHeight: desktopConfig.slideBottomHeight);
      flutterFloatingHome.flutterFloatingController.open(context);
      flutterFloatingHome.flutterFloatingController.showFloating();
    }
  }

  closeOverlay({SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT}) {
    if (platformParams.mobile) {
      mobileSystemAlertHome.closeOverlay();
    } else {
      flutterFloatingHome.flutterFloatingController.closeFloating();
      floatingKey = null;
    }
  }

  setOverlay(Widget enabled) {
    mobileSystemAlertOverlay.enabled.value = enabled;
  }

  @override
  Widget build(BuildContext context) {
    return platformParams.mobile ? mobileSystemAlertHome : flutterFloatingHome;
  }
}
