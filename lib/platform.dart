import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:device_info/device_info.dart';

/**
 * 平台的参数，包括平台的硬件和系统软件特征
 */
class PlatformParams {
  ///在loading页面创建的时候初始化,包含屏幕大小，系统字体，语言，黑暗明亮模式等信息
  late MediaQueryData mediaQueryData;

  ///直接获取的平台信息，包含操作系统版本，类型，语言，国别，主机名等
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
    return (mediaQueryData.size.width < 481);
  }

  /**
   * 可以采用移动窄屏的样式
   */
  bool ifMobileStyle() {
    return (mediaQueryData.size.width < 481 ||
            mediaQueryData.size.height < 481) ||
        ((this.isAndroid || this.isIOS));
  }
}
