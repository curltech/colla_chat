import 'dart:core';
import 'dart:io' as io;

import 'package:colla_chat/plugin/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 平台的参数，包括平台的硬件和系统软件特征，是只读的数据
class PlatformParams {
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

  late Map<String, dynamic> deviceData;
  late String path;

  Future<void> init() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (io.Platform.isAndroid ||
          io.Platform.isIOS ||
          io.Platform.isWindows ||
          io.Platform.isMacOS ||
          io.Platform.isLinux) {
        ios = io.Platform.isIOS;
        android = io.Platform.isAndroid;
        linux = io.Platform.isLinux;
        macos = io.Platform.isMacOS;
        windows = io.Platform.isWindows;
      } else {
        web = true;
      }
    } catch (e) {
      logger.e('init:$e');
      web = true;
    }

    var dir = await getApplicationDocumentsDirectory();
    path = dir.path;

    try {
      var locales = io.Platform.localeName.split('_');
      if (locales.length == 2) {
        locale = Locale(locales[0], locales[1]);
      }
      if (locales.length == 1) {
        locale = Locale(locales[0]);
      }
      localHostname = io.Platform.localHostname;
      operatingSystem = io.Platform.operatingSystem;
      operatingSystemVersion = io.Platform.operatingSystemVersion;
      version = io.Platform.version;
      if (android) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (ios) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      } else if (linux) {
        deviceData = _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
      } else if (macos) {
        deviceData = _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
      } else if (windows) {
        deviceData = _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
      } else if (web) {
        deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      }
    } catch (e) {
      logger.e('init:$e');
    }
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
      locale = Locale(locales[0], locales[1]);
    }
    operatingSystem = data.platform;
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

  bool get desktop {
    return windows || macos || linux;
  }

  bool get mobile {
    return ios || android;
  }
}

final PlatformParams platformParams = PlatformParams();
