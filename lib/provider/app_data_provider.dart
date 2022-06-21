import 'dart:convert';

import 'package:colla_chat/tool/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/address.dart';

class Option {
  String label;
  String value;
  String? hint;

  Option(this.label, this.value, {this.hint});
}

/// 不同语言版本的下拉选择框的选项
final localeOptions = [
  Option('中文', 'zh_CN'),
  Option('繁体中文', 'zh_TW'),
  Option('English', 'en_US'),
  Option('日本語', 'ja_JP'),
  Option('한국어', 'ko_KR')
];

class LocalStorage {
  static final LocalStorage _instance = LocalStorage();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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
    _secureStorage.write(key: key, value: value);
    //prefs.setString(key, value);
  }

  Future<String?> get(String key) {
    return _secureStorage.read(key: key);
    //return prefs.get(key);
  }

  remove(String key) {
    _secureStorage.delete(key: key);
    prefs.remove(key);
  }
}

class NodeAddress {
  static const defaultName = 'default';
  String name;
  String? httpConnectAddress; //https服务器
  String? wsConnectAddress; //wss服务器
  String? libp2pConnectAddress; //libp2p服务器
  //ice服务器
  List<Map<String, String>>? iceServers;
  String? username;
  String? credential;

  // libp2p的链协议号码
  String? chainProtocolId;

  // 目标的libp2p节点的peerId
  String? connectPeerId;

  NodeAddress(this.name,
      {this.httpConnectAddress,
      this.wsConnectAddress,
      this.libp2pConnectAddress,
      this.iceServers,
      this.username,
      this.credential,
      this.connectPeerId,
      this.chainProtocolId}) {
    setIceServers();
  }

  NodeAddress.fromJson(Map json)
      : name = json['name'],
        httpConnectAddress = json['httpConnectAddress'],
        wsConnectAddress = json['wsConnectAddress'],
        libp2pConnectAddress = json['libp2pConnectAddress'],
        iceServers = json['iceServers'],
        username = json['username'],
        credential = json['credential'],
        connectPeerId = json['connectPeerId'],
        chainProtocolId = json['chainProtocolId'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'name': name,
      'httpConnectAddress': httpConnectAddress,
      'wsConnectAddress': wsConnectAddress,
      'libp2pConnectAddress': libp2pConnectAddress,
      'iceServers': iceServers,
      'username': username,
      'credential': credential,
      'connectPeerId': connectPeerId,
      'chainProtocolId': chainProtocolId,
    });
    return json;
  }

  setIceServers() {
    var ices = iceServers;
    if (ices != null && ices.isNotEmpty) {
      for (var iceServer in ices) {
        if (username != null) {
          iceServer['username'] = username!;
        }
        if (credential != null) {
          iceServer['credential'] = credential!;
        }
      }
    }
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

/// 本应用的参数状态管理器，与操作系统系统和硬件无关，需要保存到本地的存储中
/// 在系统启动的对象初始化从本地存储中加载
class AppDataProvider with ChangeNotifier {
  static AppDataProvider instance = AppDataProvider();
  static bool initStatus = false;

  /// 可选的连接地址，比如http、ws、libp2p、turn
  Map<String, NodeAddress> nodeAddress = nodeAddressOptions;
  var topics = <String>[]; //订阅的主题
  // 本机作为libp2p节点的监听地址
  var listenerAddress = <String>[];
  var chainProtocolId = '/chain/1.0.0';

  ///locale和Theme属性
  String _locale = 'zh_CN';
  MaterialColor? _primarySwatch = Colors.cyan;
  MaterialColor? _seedColor = Colors.cyan;
  String _fontFamily = '';
  String _brightness = 'light';
  ThemeData? _themeData;

  //屏幕宽高
  double _keyboardHeight = 270.0;
  Size _size = const Size(0.0, 0.0);
  double leftBarWidth = 90;
  String sqlite3Path = '';

  AppDataProvider();

  ///初始化一些参数
  static Future<AppDataProvider> init() async {
    if (!initStatus) {
      LocalStorage localStorage = await LocalStorage.instance;
      Object? json = await localStorage.get('AppParams');
      if (json != null) {
        Map<dynamic, dynamic> jsonObject = JsonUtil.toMap(json as String);
        instance = AppDataProvider.fromJson(jsonObject as Map<String, dynamic>);
      }
      Logger.level = Level.warning;
      initStatus = true;
    }
    return instance;
  }

  ///序列化和反序列化操作
  AppDataProvider.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};

  /// locale操作
  Locale getLocale() {
    var locales = _locale.split('_');
    return Locale(locales[0], locales[1]);
  }

  setLocale(Locale locale) {
    _locale = locale.toString();
  }

  String get locale => _locale.toString();

  set locale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  /// theme操作
  ThemeData? get themeData {
    if (_themeData == null) {
      _buildThemeData();
    }
    return _themeData;
  }

  _buildThemeData() {
    Brightness brightness =
        Brightness.values.firstWhere((element) => element.name == _brightness);
    ColorScheme colorScheme;
    if (_seedColor != null) {
      colorScheme = ColorScheme.fromSeed(
          seedColor: _seedColor ?? Colors.cyan, brightness: brightness);
    } else if (_primarySwatch != null) {
      colorScheme = ColorScheme.fromSwatch(
          primarySwatch: _primarySwatch ?? Colors.cyan, brightness: brightness);
    } else {
      colorScheme =
          ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: brightness);
    }
    TextTheme textTheme;
    if (_fontFamily != '') {
      textTheme = GoogleFonts.getTextTheme(_fontFamily);
    } else {
      textTheme = const TextTheme();
    }

    _themeData = ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: brightness,
    );
  }

  MaterialColor? get seedColor {
    return _seedColor;
  }

  set seedColor(MaterialColor? color) {
    _seedColor = color;
    _primarySwatch = null;
    _buildThemeData();
    notifyListeners();
  }

  MaterialColor? get primarySwatch {
    return _primarySwatch;
  }

  set primarySwatch(MaterialColor? color) {
    _seedColor = null;
    _primarySwatch = color;
    _buildThemeData();
    notifyListeners();
  }

  String get fontFamily {
    return _fontFamily;
  }

  set fontFamily(String fontFamily) {
    _fontFamily = fontFamily;
    _buildThemeData();
    notifyListeners();
  }

  String get brightness {
    return _brightness;
  }

  set brightness(String brightness) {
    _brightness = brightness;
    _buildThemeData();
    notifyListeners();
  }

  Size get size {
    return _size;
  }

  Size get workspaceSize {
    double width = _size.width - leftBarWidth;
    double height = _size.height;
    if (mobile) {
      height = height - 80;
    }

    return Size(width, height);
  }

  set size(Size size) {
    if (_size.height != size.height || _size.width != size.width) {
      _size = size;
      logger.i(
          'Screen size changed:height ${_size.height},width  ${_size.width}');
    }
  }

  bool get mobile {
    return _size.height > _size.width;
  }

  double get keyboardHeight {
    return _keyboardHeight;
  }

  set keyboardHeight(double keyboardHeight) {
    if (_keyboardHeight != keyboardHeight) {
      _keyboardHeight = keyboardHeight;
      logger.i('keyboardHeight changed:$_keyboardHeight');
    }
  }

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

  ///当外部改变屏幕大小的时候引起index页面的重建，从而调用这个方法改变size
  changeSize(BuildContext context) {
    size = MediaQuery.of(context).size;
    var keyboardHeight = appDataProvider.keyboardHeight;
    if (keyboardHeight == 270.0 &&
        MediaQuery.of(context).viewInsets.bottom != 0) {
      keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    }
  }
}

var appDataProvider = AppDataProvider();

var logger = Logger(
  printer: PrettyPrinter(),
  level: Level.info,
);

//var log = easylogger.Logger;
