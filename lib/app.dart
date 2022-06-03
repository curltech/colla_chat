import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:colla_chat/tool/util.dart';
import 'package:flutter/material.dart';
import 'package:colla_chat/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'constant/address.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage();
  late SharedPreferences prefs;
  static bool initStatus = false;

  static Future<LocalStorage> get instance async {
    if (!initStatus) {
      _instance.prefs = await SharedPreferences.getInstance();
      initStatus = true;
    }
    return _instance;
  }

  save(String key, String value) {
    prefs.setString(key, value);
  }

  get(String key) {
    return prefs.get(key);
  }

  remove(String key) {
    prefs.remove(key);
  }
}

class NodeAddress {
  static final defaultName = 'default';
  String name;
  String? httpConnectAddress; //https服务器
  String? wsConnectAddress; //wss服务器
  String? libp2pConnectAddress; //libp2p服务器
  String? iceServers; //ice服务器
  // libp2p的链协议号码
  String? chainProtocolId;

  // 目标的libp2p节点的peerId
  String? connectPeerId = '';

  NodeAddress(this.name,
      {this.httpConnectAddress,
      this.wsConnectAddress,
      this.libp2pConnectAddress,
      this.iceServers,
      this.connectPeerId,
      this.chainProtocolId});

  NodeAddress.fromJson(Map json)
      : name = json['name'],
        httpConnectAddress = json['httpConnectAddress'],
        wsConnectAddress = json['wsConnectAddress'],
        libp2pConnectAddress = json['libp2pConnectAddress'],
        iceServers = json['iceServers'],
        connectPeerId = json['connectPeerId'],
        chainProtocolId = json['chainProtocolId'];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'name': name,
      'httpConnectAddress': httpConnectAddress,
      'wsConnectAddress': wsConnectAddress,
      'libp2pConnectAddress': libp2pConnectAddress,
      'iceServers': iceServers,
      'connectPeerId': connectPeerId,
      'chainProtocolId': chainProtocolId,
    });
    return json;
  }

  void validate(NodeAddress address) {
    if (address.name == '') {
      throw 'NameFormatError';
    }
    var wsConnectAddress = address.wsConnectAddress;
    if (wsConnectAddress != null) {
      if (!wsConnectAddress.startsWith('wss') &&
          !wsConnectAddress.startsWith('ws')) {
        throw 'WsConnectAddressFormatError';
      }
    }
    var httpConnectAddress = address.httpConnectAddress;
    if (httpConnectAddress != null) {
      if (!httpConnectAddress.startsWith('https') &&
          !httpConnectAddress.startsWith('http')) {
        throw 'HttpConnectAddressFormatError';
      }
    }
    var libp2pConnectAddress = address.libp2pConnectAddress;
    if (libp2pConnectAddress != null) {
      if (!libp2pConnectAddress.startsWith('/dns') &&
          !libp2pConnectAddress.startsWith('/ip')) {
        throw 'Libp2pConnectAddressFormatError';
      }
    }
  }
}

/// 本应用的参数，与操作系统系统和硬件无关，需要保存到本地的存储中
/// 在系统启动的config对象初始化从本地存储中加载
class AppParams {
  static AppParams instance = AppParams();

  static bool initStatus = false;

  AppParams();

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

  /// 可选的连接地址，比如http、ws、libp2p、turn
  Map<String, NodeAddress> nodeAddress = nodeAddressOptions;
  var topics = <String>[]; //订阅的主题

  // 本机作为libp2p节点的监听地址
  var listenerAddress = <String>[];

  static Future<AppParams> init() async {
    if (!initStatus) {
      LocalStorage localStorage = await LocalStorage.instance;
      Object? json = localStorage.get('AppParams');
      if (json != null) {
        Map<dynamic, dynamic> jsonObject = JsonUtil.toMap(json as String);
        instance = AppParams.fromJson(jsonObject as Map<String, dynamic>);
      }
      Logger.level = Level.warning;
      initStatus = true;
    }
    return instance;
  }

  AppParams.fromJson(Map<String, dynamic> json)
      : language = json['language'],
        mode = json['mode'];

  Map<String, dynamic> toJson() => {
        'language': language,
        'mode': mode,
      };

  setConnectAddress(NodeAddress address) {
    address.validate(address);
    nodeAddress[address.name] = address;
  }

  /// 缺省连接地址
  NodeAddress get defaultNodeAddress {
    var d = nodeAddress[NodeAddress.defaultName];
    if (d == null) {
      throw 'NoDefaultNodeAddress';
    }
    return d;
  }

  set defaultNodeAddress(NodeAddress address) {
    nodeAddress[NodeAddress.defaultName] = address;
  }

  saveAppParams() async {
    var jsonObject = toJson();
    var json = jsonEncode(jsonObject);
    LocalStorage localStorage = await LocalStorage.instance;
    localStorage.save('AppParams', json);
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
  updateVersion() async {
    var appleUrl = 'https://apps.apple.com/cn/app/collachat/id1546363298';
    var downloadUrl = 'https://curltech.io/#/collachat/downloadapps';
    var platformParams = await PlatformParams.instance;
    if (platformParams.ios) {
      //inAppBrowserComponent.open(appleUrl, '_system', 'location=no')
    } else if (platformParams.android) {
      //inAppBrowserComponent.open(downloadUrl, '_system', 'location=no')
    } else if (platformParams.macos) {
      //window.open(appleUrl, '_blank')
    } else {
      //window.open(downloadUrl, '_blank')
    }
  }

  /// 根据版本历史修改版本信息
  /// @param versions
  Future<bool> upgradeVersion(List<String> versions) async {
    var appParams = await AppParams.instance;
    appParams.currentVersion = '1.1.12';
    appParams.mandatory = false;
    if (versions.isNotEmpty) {
      var no = 1;
      for (var version in versions) {
        var currentVersion = appParams.currentVersion;
        if (checkVersion(currentVersion!, version)) {
          if (no == 1) {
            appParams.latestVersion = version.replaceAll('/[vV]/', '');
          }
          if (version.substring(0, 1) == 'V') {
            appParams.mandatory = true;
            break;
          }
        } else {
          break;
        }
        no++;
      }
      appParams.latestVersion ??= appParams.currentVersion;
      return (appParams.latestVersion != appParams.currentVersion);
    }

    return false;
  }
}

/// 全局配置，包含平台参数和应用参数
class Config {
  static final Config _instance = Config();
  static bool initStatus = false;

  static Future<Config> get instance async {
    if (!initStatus) {
      initStatus = true;
    }
    return _instance;
  }
}

var logger = Logger(
  printer: PrettyPrinter(),
);
