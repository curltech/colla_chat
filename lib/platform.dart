import 'dart:core';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/**
 * 平台的参数，包括平台的硬件和系统软件特征
 */
class PlatformParams {
  static final PlatformParams _instance = PlatformParams();
  static bool initStatus = false;

  ///在loading页面创建的时候初始化,包含屏幕大小，系统字体，语言，黑暗明亮模式等信息
  late MediaQueryData mediaQueryData;

  ///直接获取的平台信息，包含操作系统版本，类型，语言，国别，主机名等
  late bool web;
  late bool ios;
  late bool android = false;
  late bool linux;
  late bool macos;
  late bool windows;
  String? localeName;
  String? localHostname;
  String? operatingSystem;
  String? operatingSystemVersion;
  String? version;
  String? dark;
  String? phoneNumber;
  String? countryCode;
  String? language;
  String? clientDevice;
  String? clientType;

  late Map<String, dynamic> deviceData;
  late Map<String, dynamic>? webDeviceData;

  static Future<PlatformParams> get instance async {
    if (!initStatus) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          _instance.ios = Platform.isIOS;
          _instance.android = Platform.isAndroid;
          _instance.linux = Platform.isLinux;
          _instance.macos = Platform.isMacOS;
          _instance.windows = Platform.isWindows;
          _instance.localeName = Platform.localeName;
          _instance.localHostname = Platform.localHostname;
          _instance.operatingSystem = Platform.operatingSystem;
          _instance.operatingSystemVersion = Platform.operatingSystemVersion;
          _instance.version = Platform.version;
          if (Platform.isAndroid) {
            _instance.deviceData = _instance
                ._readAndroidBuildData(await deviceInfoPlugin.androidInfo);
          } else if (Platform.isIOS) {
            _instance.deviceData =
                _instance._readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
          } else if (Platform.isLinux) {
            _instance.deviceData = _instance
                ._readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
          } else if (Platform.isMacOS) {
            _instance.deviceData = _instance
                ._readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
          } else if (Platform.isWindows) {
            _instance.deviceData = _instance
                ._readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
          }
        } else {
          _instance.web = true;
        }
      } catch (e) {
        _instance.web = true;
      }
      if (_instance.web) {
        _instance.webDeviceData = _instance
            ._readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      }
      initStatus = true;
    }
    return _instance;
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': build.androidId,
      'systemFeatures': build.systemFeatures,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'version': data.version,
      'id': data.id,
      'idLike': data.idLike,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId,
    };
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic>{
      'browserName': describeEnum(data.browserName),
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory,
      'language': data.language,
      'languages': data.languages,
      'platform': data.platform,
      'product': data.product,
      'productSub': data.productSub,
      'userAgent': data.userAgent,
      'vendor': data.vendor,
      'vendorSub': data.vendorSub,
      'hardwareConcurrency': data.hardwareConcurrency,
      'maxTouchPoints': data.maxTouchPoints,
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.computerName,
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'osRelease': data.osRelease,
      'activeCPUs': data.activeCPUs,
      'memorySize': data.memorySize,
      'cpuFrequency': data.cpuFrequency,
      'systemGUID': data.systemGUID,
    };
  }

  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
    };
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
        ((this.android || this.ios));
  }
}
