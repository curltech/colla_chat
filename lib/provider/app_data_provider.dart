import 'dart:convert';

import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 不同语言版本的下拉选择框的选项
final localeOptions = [
  Option('中文', 'zh_CN'),
  Option('繁体中文', 'zh_TW'),
  Option('English', 'en_US'),
  Option('日本語', 'ja_JP'),
  Option('한국어', 'ko_KR')
];

/// 本应用的参数状态管理器，与操作系统系统和硬件无关，需要保存到本地的存储中
/// 在系统启动的对象初始化从本地存储中加载
class AppDataProvider with ChangeNotifier {
  var topics = <String>[]; //订阅的主题
  // 本机作为libp2p节点的监听地址
  var listenerAddress = <String>[];
  var chainProtocolId = '/chain/1.0.0';

  ///locale和Theme属性
  String _locale = 'zh_CN';
  MaterialColor? _primarySwatch = Colors.cyan;
  Color _seedColor = Colors.cyan;
  String _fontFamily = '';
  String _brightness = 'light'; //or dark / system
  ThemeData _themeData = ThemeData();

  //屏幕宽高
  double _keyboardHeight = 270.0;
  final Size _mobileSize = Size(412.0, 869.0);
  Size _size = const Size(0.0, 0.0);
  double bottomBarHeight = kBottomNavigationBarHeight;
  double toolbarHeight = kToolbarHeight;
  String sqlite3Path = '';

  AppDataProvider();

  ///初始化一些参数
  Future<void> init() async {
    Object? json = await localSecurityStorage.get('AppParams');
    if (json != null) {
      Map<dynamic, dynamic> jsonObject = JsonUtil.toJson(json as String);
    }
    _buildThemeData();
    notifyListeners();
  }

  ///序列化和反序列化操作
  AppDataProvider.fromJson(Map<String, dynamic> json) {}

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
  ThemeData get themeData {
    return _themeData;
  }

  ThemeMode get themeMode {
    ThemeMode themeMode =
        ThemeMode.values.firstWhere((element) => element.name == _brightness);
    return themeMode;
  }

  _buildThemeData() {
    Brightness brightness =
        Brightness.values.firstWhere((element) => element.name == _brightness);
    ColorScheme colorScheme;
    colorScheme =
        ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
    TextTheme textTheme;
    if (_fontFamily != '') {
      textTheme = GoogleFonts.getTextTheme(_fontFamily);
    } else {
      textTheme = const TextTheme();
    }

    IconThemeData iconTheme = IconThemeData(color: colorScheme.primary);

    _themeData = ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      iconTheme: iconTheme,
      brightness: brightness,
    );
  }

  Color get seedColor {
    return _seedColor;
  }

  set seedColor(Color color) {
    _seedColor = color;
    _primarySwatch = null;
    _buildThemeData();
    notifyListeners();
  }

  MaterialColor? get primarySwatch {
    return _primarySwatch;
  }

  set primarySwatch(MaterialColor? color) {
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
    double width = _size.width;
    double height = _size.height;
    height = height - bottomBarHeight;

    return Size(width, height);
  }

  Size get mobileSize {
    double width =
        _size.width < _mobileSize.width ? _size.width : _mobileSize.width;
    double height =
        _size.height < _mobileSize.height ? _size.height : _mobileSize.height;
    height = height - bottomBarHeight;

    return Size(width, height);
  }

  set size(Size size) {
    if (_size.height != size.height || _size.width != size.width) {
      _size = size;
      // logger.i(
      //     'Screen size changed:height ${_size.height},width  ${_size.width}');
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
      //logger.i('keyboardHeight changed:$_keyboardHeight');
    }
  }

  saveAppParams() async {
    var jsonObject = toJson();
    var json = jsonEncode(jsonObject);
    localSecurityStorage.save('AppParams', json);
  }

  ///当外部改变屏幕大小的时候引起index页面的重建，从而调用这个方法改变size
  changeSize(BuildContext context) {
    size = MediaQuery.of(context).size;
    var keyboardHeight = appDataProvider.keyboardHeight;
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight == 270.0 && bottom != 0) {
      appDataProvider.keyboardHeight = bottom;
    }
  }
}

var appDataProvider = AppDataProvider();
