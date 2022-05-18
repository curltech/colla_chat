import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:colla_chat/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './constants.dart';

class LocalStorage {
  static SharedPreferences? prefs;

  static initSP() async {
    prefs = await SharedPreferences.getInstance();
  }

  static save(String key, String value) {
    prefs?.setString(key, value);
  }

  static get(String key) {
    return prefs?.get(key);
  }

  static remove(String key) {
    prefs?.remove(key);
  }
}

/// 本应用的参数，与操作系统系统和硬件无关，需要保存到本地的存储中
/// 在系统启动的config对象初始化从本地存储中加载
class AppParams {
  //本应用的版本情况
  String? latestVersion;
  String? currentVersion;
  bool? mandatory;

  String? deviceToken;
  String? p2pProtocol;
  String? timeFormat;
  String? mode;
  String? language;
  String? localeName;

  AppParams.fromJson(Map<String, dynamic> json)
      : language = json['language'],
        mode = json['mode'];

  Map<String, dynamic> toJson() => {
        'language': language,
        'mode': mode,
      };

  /// 各种语言的连接地址选项，从服务器获取，或者是常量定义
  var connectAddressOptionsISO = Constants.connectAddressOptionsISO;

  /// 可选的连接地址，比如http、ws、libp2p、turn
  var httpConnectAddress = <String>['https://localhost:9091']; //https服务器
  var wsConnectAddress = <String>[]; //wss服务器
  var libp2pConnectAddress = <String>[]; //libp2p服务器
  var iceServers = <String>[]; //ice服务器

  // libp2p的链协议号码
  String? chainProtocolId;
  // 目标的libp2p节点的peerId
  var connectPeerId = <String>[];
  // 本机作为libp2p节点的监听地址
  var listenerAddress = <String>[];

  /**
   * 设置第一个连接地址，自动识别https，wss，libp2p协议
   */
  setConnectAddress(String address) {
    if (address.startsWith('wss') || address.startsWith('ws')) {
      wsConnectAddress[0] = address;
    } else if (address.startsWith('https') || address.startsWith('http')) {
      httpConnectAddress[0] = address;
    } else if (address.startsWith('/dns') || address.startsWith('/ip')) {
      libp2pConnectAddress[0] = address;
    }
  }

  /**
   * 增加一个连接地址，自动识别https，wss，libp2p协议
   */
  addConnectAddress(String address) {
    if (address.startsWith('wss') || address.startsWith('ws')) {
      wsConnectAddress.add(address);
    } else if (address.startsWith('https') || address.startsWith('http')) {
      httpConnectAddress.add(address);
    } else if (address.startsWith('/dns') || address.startsWith('/ip')) {
      libp2pConnectAddress.add(address);
    }
  }

  /// 检查版本
  /// @param currentVersion
  /// @param version
  bool checkVersion(String currentVersion, String version) {
    currentVersion = currentVersion != null
        ? currentVersion.replaceAll('/[vV]/', '')
        : '0.0.0';
    version = version != null ? version.replaceAll('/[vV]/', '') : '0.0.0';
    if (currentVersion == version) {
      return false;
    }
    var currentVerArr = currentVersion.split(".");
    var verArr = version.split(".");
    var len = max(currentVerArr.length, verArr.length);
    for (var i = 0; i < len; i++) {
      var currentVer = int.parse(currentVerArr[i]);
      var ver = int.parse(verArr[i]);
      if (currentVer < ver) {
        return true;
      }
    }
    return false;
  }

  /// 进入版本升级下载页面
  updateVersion() {
    var appleUrl = 'https://apps.apple.com/cn/app/collachat/id1546363298';
    var downloadUrl = 'https://curltech.io/#/collachat/downloadapps';
    if (config.platformParams.isIOS) {
      //inAppBrowserComponent.open(appleUrl, '_system', 'location=no')
    } else if (config.platformParams.isAndroid) {
      //inAppBrowserComponent.open(downloadUrl, '_system', 'location=no')
    } else if (config.platformParams.isMacOS) {
      //window.open(appleUrl, '_blank')
    } else {
      //window.open(downloadUrl, '_blank')
    }
  }

  /// 根据版本历史修改版本信息
  /// @param versions
  bool upgradeVersion(List<String> versions) {
    config.appParams.currentVersion = '1.1.12';
    config.appParams.mandatory = false;
    if (versions.isNotEmpty) {
      var no = 1;
      for (var version in versions) {
        var currentVersion = config.appParams.currentVersion;
        if (checkVersion(currentVersion!, version)) {
          if (no == 1) {
            config.appParams.latestVersion = version.replaceAll('/[vV]/', '');
          }
          if (version.substring(0, 1) == 'V') {
            config.appParams.mandatory = true;
            break;
          }
        } else {
          break;
        }
        no++;
      }
      config.appParams.latestVersion ??= config.appParams.currentVersion;
      return (config.appParams.latestVersion !=
          config.appParams.currentVersion);
    }

    return false;
  }
}

/// 全局配置，包含平台参数和应用参数
class Config {
  PlatformParams platformParams = PlatformParams();
  late AppParams appParams;

  Config() {
    String json = LocalStorage.get('AppParams');
    var jsonObject = jsonDecode(json);
    appParams = AppParams.fromJson(jsonObject);
  }

  saveAppParams() {
    var jsonObject = appParams.toJson();
    var json = jsonEncode(jsonObject);
    LocalStorage.save('AppParams', json);
  }
}

final config = Config();
