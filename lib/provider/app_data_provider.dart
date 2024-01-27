import 'package:colla_chat/pages/chat/index/platform_breakpoint.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';

/// 不同语言版本的下拉选择框的选项
final localeOptions = [
  Option('English', LocaleUtil.getLocale('en_US'), hint: ''),
  Option('中文', LocaleUtil.getLocale('zh_CN'), hint: ''),
  Option('繁体中文', LocaleUtil.getLocale('zh_TW'), hint: ''),
  Option('日本語', LocaleUtil.getLocale('ja_JP'), hint: ''),
  Option('한국어', LocaleUtil.getLocale('ko_KR'), hint: '')
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
  double primaryNavigationWidth = 170;
  double mediumPrimaryNavigationWidth = 90;
  int _bodyRatio = 40;
  double dividerWidth = 1;
  double topPadding = 0;
  double bottomPadding = 0;
  double textScaleFactor = 1.0;
  String sqlite3Path = '';
  int dataLength = 0;
  bool _autoLogin = false;

  AppDataProvider();

  ///总的屏幕尺寸
  Size get totalSize {
    return _totalSize;
  }

  Size get designSize {
    //特殊效果的尺寸，宽度最大是412，高度最大是892
    return const Size(412.0, 892.0);
  }

  ///竖屏尺寸，在竖屏的情况下，等于总尺寸，
  ///在横屏的情况下，用于登录等小页面的尺寸，露出后面的背景图像，等于竖屏设计尺寸与实际尺寸取较小值
  Size get portraitSize {
    double width = _totalSize.width;
    double height = _totalSize.height;
    //横屏需要根据固定的尺寸来计算
    if (landscape) {
      width = _totalSize.width < designSize.width
          ? _totalSize.width
          : designSize.width;
      height = _totalSize.height < designSize.height
          ? _totalSize.height
          : designSize.height;
    }

    return Size(width, height);
  }

  static const double smallBreakpointLimit = 600;
  static const double largeBreakpointLimit = 1000;

  ///横屏，宽度大于高度而且宽度大于最小宽度
  bool get landscape {
    return _totalSize.width > _totalSize.height &&
        _totalSize.width >= smallBreakpointLimit;
  }

  ///竖屏，宽度小于高度或者宽度小于600
  PlatformBreakpoint get smallBreakpoint {
    return const PlatformBreakpoint(end: smallBreakpointLimit);
  }

  ///横屏，宽度大于600并且小于1000，并且宽度大于高度
  PlatformBreakpoint get mediumBreakpoint {
    return const PlatformBreakpoint(
        begin: smallBreakpointLimit, end: largeBreakpointLimit);
  }

  ///大横屏，宽度大于1000，并且宽度大于高度
  PlatformBreakpoint get largeBreakpoint {
    return const PlatformBreakpoint(begin: largeBreakpointLimit);
  }

  ///计算实际的主视图宽度，在竖屏的情况下始终为0，
  double get bodyWidth {
    double width = portraitSize.width;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        width = totalSize.width - primaryNavigationWidth;
        width = width * bodyRatio;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        width = totalSize.width - mediumPrimaryNavigationWidth;
        width = width * bodyRatio;
      } else {
        width = 0.0;
      }
    } else {
      width = 0.0;
    }
    return width;
  }

  double get bodyRatio {
    return _bodyRatio / 100;
  }

  set bodyRatio(double bodyRatio) {
    int r = (bodyRatio * 100).toInt();
    if (_bodyRatio != r) {
      _bodyRatio = r;
      notifyListeners();
    }
  }

  changeBodyRatio() {
    if (_bodyRatio < 30) {
      if (_totalSize.width >= largeBreakpointLimit) {
        _bodyRatio = 40;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        _bodyRatio = 50;
      }
    } else if (_bodyRatio == 30) {
      _bodyRatio = 0;
    } else {
      _bodyRatio = _bodyRatio - 5;
    }
    notifyListeners();
  }

  ///计算实际的当前视图宽度
  double get secondaryBodyWidth {
    double width = portraitSize.width;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        width = totalSize.width - primaryNavigationWidth;
        width = width * (1 - bodyRatio);
      } else if (_totalSize.width >= smallBreakpointLimit) {
        width = totalSize.width - mediumPrimaryNavigationWidth;
        width = width * (1 - bodyRatio);
      } else {
        width = portraitSize.width;
      }
    } else {
      width = _totalSize.width;
    }
    return width;
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
      if (_bodyRatio > 0) {
        if (_totalSize.width >= largeBreakpointLimit) {
          _bodyRatio = 40;
        } else if (_totalSize.width >= smallBreakpointLimit) {
          _bodyRatio = 50;
        }
      }
      // logger.i('Total size: $_totalSize');
    }
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    if (_keyboardHeight == 270.0 && bottom != 0) {
      _keyboardHeight = bottom;
      // logger.i('KeyboardHeight: $_keyboardHeight');
    }
    // logger.i('bottomBarHeight: $bottomBarHeight');
    // logger.i('toolbarHeight: $toolbarHeight');
    // 上下边距 （主要用于 刘海  和  内置导航键）
    topPadding = MediaQuery.of(context).padding.top;
    // logger.i('topPadding: $topPadding');
    bottomPadding = MediaQuery.of(context).padding.bottom;
    // logger.i('bottomPadding: $bottomPadding');

    textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // logger.i('textScaleFactor: $textScaleFactor');
  }
}

var appDataProvider = AppDataProvider();
