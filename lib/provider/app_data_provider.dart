import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';

/// 不同语言版本的下拉选择框的选项
final localeOptions = [
  Option('中文', LocaleUtil.getLocale('zh_CN')),
  Option('繁体中文', LocaleUtil.getLocale('zh_TW')),
  Option('English', LocaleUtil.getLocale('en_US')),
  Option('日本語', LocaleUtil.getLocale('ja_JP')),
  Option('한국어', LocaleUtil.getLocale('ko_KR'))
];

/// 本应用的参数状态管理器，与操作系统系统和硬件无关
/// 在系统启动的对象初始化从本地存储中加载
class AppDataProvider with ChangeNotifier {
  List<String> topics = [];

  //屏幕宽高
  double _keyboardHeight = 270.0;
  Size _totalSize = const Size(412.0, 892.0);
  double bottomBarHeight = kBottomNavigationBarHeight;
  double toolbarHeight = kToolbarHeight;
  String sqlite3Path = '';
  bool _autoLogin = false;

  AppDataProvider();

  ///总的屏幕尺寸
  Size get totalSize {
    return _totalSize;
  }

  Size get workspaceSize {
    double width = _totalSize.width;
    double height = _totalSize.height;
    height = height - bottomBarHeight;

    return Size(width, height);
  }

  Size get designSize {
    //特殊效果的尺寸，宽度最大是412，高度最大是892
    return const Size(412.0, 892.0);
  }

  ///实际的屏幕尺寸，也是玻璃等特殊效果的尺寸，对移动设备来说，与总尺寸一致，
  ///对桌面来说，是登录等小页面的尺寸，露出后面的背景图像
  Size get actualSize {
    Size fixedSize = designSize;
    double width = _totalSize.width;
    double height = _totalSize.height;
    //桌面需要根据固定的尺寸来计算
    if (!platformParams.mobile) {
      width = _totalSize.width < fixedSize.width
          ? _totalSize.width
          : fixedSize.width;
      height = _totalSize.height < fixedSize.height
          ? _totalSize.height
          : fixedSize.height;
      //高度还要减去底部工具栏的高度
      // height = height - bottomBarHeight;
    }

    return Size(width, height);
  }

  bool get landscape {
    return _totalSize.height > _totalSize.width;
  }

  bool get portrait {
    return _totalSize.height < _totalSize.width;
  }

  double get keyboardHeight {
    return _keyboardHeight;
  }

  set keyboardHeight(double keyboardHeight) {
    if (_keyboardHeight != keyboardHeight) {
      _keyboardHeight = keyboardHeight;
    }
  }

  bool get autoLogin {
    return _autoLogin;
  }

  set autoLogin(bool autoLogin) {
    if (_autoLogin != autoLogin) {
      _autoLogin = autoLogin;
      notifyListeners();
    }
  }

  ///当外部改变屏幕大小的时候引起index页面的重建，从而调用这个方法改变size
  changeSize(BuildContext context) {
    var totalSize = MediaQuery.of(context).size;
    if (totalSize.width != _totalSize.width ||
        totalSize.height != _totalSize.height) {
      _totalSize = totalSize;
      logger.i('Total size: $_totalSize');
    }
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    if (_keyboardHeight == 270.0 && bottom != 0) {
      _keyboardHeight = bottom;
      logger.i('KeyboardHeight: $_keyboardHeight');
    }
    logger.i('bottomBarHeight: $bottomBarHeight');
    logger.i('toolbarHeight: $toolbarHeight');
  }
}

var appDataProvider = AppDataProvider();
