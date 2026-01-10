import 'package:colla_chat/platform.dart';
import 'package:flutter/services.dart';

class DeviceUtil {
  /// 设置移动设备的横屏和竖屏
  static Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) async {
    if (platformParams.mobile) {
      await SystemChrome.setPreferredOrientations(orientations);
    }
  }

  /// 设置隐藏状态栏和导航栏
  static Future<void> setEnabledSystemUIMode(SystemUiMode mode,
      {List<SystemUiOverlay>? overlays}) async {
    await SystemChrome.setEnabledSystemUIMode(mode, overlays: overlays);
  }

  /// 设置状态栏样式，比如透明
  static void setSystemUIOverlayStyle(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  static void enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  static void exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }
}
