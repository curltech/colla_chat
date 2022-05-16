import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:device_info/device_info.dart';

/**
 * 平台的参数，包括平台的硬件和系统软件特征
 */
class PlatformParams {
  var isIOS = Platform.isIOS;
  var isAndroid = Platform.isAndroid;
  var isLinux = Platform.isLinux;
  var isMacOS = Platform.isMacOS;
  var isWindows = Platform.isWindows;
  var localeName = Platform.localeName;
  var localHostname = Platform.localHostname;
  var operatingSystem = Platform.operatingSystem;
  var operatingSystemVersion = Platform.operatingSystemVersion;
  var version = Platform.version;
  String? dark;
  String? phoneNumber;
  String? countryCode;
  String? language;
  String? clientDevice;
  String? clientType;
  Size? screenSize;

  setScreenSize(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
  }

  void getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    }
  }

  /**
   * 屏幕宽度较小，是移动尺寸
   */
  bool ifMobileSize() {
    return (screenSize!.width < 481);
  }

  /**
   * 可以采用移动窄屏的样式
   */
  bool ifMobileStyle() {
    return (this.screenSize!.width < 481 || this.screenSize!.height < 481) ||
        ((this.isAndroid || this.isIOS));
  }
}
