import 'dart:core';
import 'dart:io' as io;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// 平台的参数，包括平台的硬件和系统软件特征，是只读的数据
class PlatformParams {
  static PlatformParams instance = PlatformParams();
  static bool initStatus = false;

  ///在loading页面创建的时候初始化,包含屏幕大小，系统字体，语言，黑暗明亮模式等信息
  late MediaQueryData mediaQueryData;

  ///直接获取的平台信息，包含操作系统版本，类型，语言，国别，主机名等
  bool web = false;
  bool ios = false;
  bool android = false;
  bool linux = false;
  bool macos = false;
  bool windows = false;
  Locale? locale;
  String? localHostname;
  String? operatingSystem;
  String? operatingSystemVersion;
  String? version;
  String? brightness;
  String? phoneNumber;
  String? clientDevice;

  late Map<String, dynamic> deviceData;
  late Map<String, dynamic>? webDeviceData;

  static Future<PlatformParams> init() async {
    if (!initStatus) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      try {
        if (io.Platform.isAndroid ||
            io.Platform.isIOS ||
            io.Platform.isWindows ||
            io.Platform.isMacOS ||
            io.Platform.isLinux) {
          instance.ios = io.Platform.isIOS;
          instance.android = io.Platform.isAndroid;
          instance.linux = io.Platform.isLinux;
          instance.macos = io.Platform.isMacOS;
          instance.windows = io.Platform.isWindows;
          var locales = io.Platform.localeName.split('_');
          instance.locale = Locale(locales[0], locales[1]);
          instance.localHostname = io.Platform.localHostname;
          instance.operatingSystem = io.Platform.operatingSystem;
          instance.operatingSystemVersion = io.Platform.operatingSystemVersion;
          instance.version = io.Platform.version;
          if (io.Platform.isAndroid) {
            instance.deviceData = instance
                ._readAndroidBuildData(await deviceInfoPlugin.androidInfo);
          } else if (io.Platform.isIOS) {
            instance.deviceData =
                instance._readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
            instance.deviceData =
                instance._readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
          } else if (io.Platform.isMacOS) {
            instance.deviceData =
                instance._readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
          } else if (io.Platform.isWindows) {
            instance.deviceData = instance
                ._readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
          }
        } else {
          instance.web = true;
        }
      } catch (e) {
        instance.web = true;
      }
      if (instance.web) {
        instance.webDeviceData =
            instance._readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      }
      initStatus = true;
    }
    return instance;
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
    var language = data.language;
    if (language != null) {
      var locales = language.split('-');
      instance.locale = Locale(locales[0], locales[1]);
    }
    instance.clientDevice = data.appVersion;
    instance.operatingSystem = data.platform;
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

  /// 屏幕宽度较小，是移动尺寸
  bool ifMobileSize() {
    return (mediaQueryData.size.width < 481);
  }

  /// 可以采用移动窄屏的样式
  bool ifMobileStyle() {
    return (mediaQueryData.size.width < 481 ||
            mediaQueryData.size.height < 481) ||
        ((this.android || this.ios));
  }
}
