import 'package:colla_chat/pages/index/platform_breakpoint.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

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
  BuildContext? context;
  List<String> topics = [];

  //屏幕宽高
  double _keyboardHeight = 270.0;
  final Size _designSize = const Size(390.0, 844.0);
  late Size _totalSize = _designSize;
  double bottomBarHeight = kBottomNavigationBarHeight;
  double toolbarHeight = kToolbarHeight;
  double primaryNavigationWidth = 90;
  double mediumPrimaryNavigationWidth = 90;

  /// 主视图宽度，并以此计算主内容视图宽度secondaryBodyWidth
  double _bodyWidth = -1;
  double dividerWidth = 1;
  double topPadding = 0;
  double bottomPadding = 0;
  TextScaler textScaler = TextScaler.noScaling;
  late String sqlite3Path;
  int dataLength = 0;
  bool _autoLogin = false;
  late Orientation orientation = Orientation.landscape;

  AppDataProvider() {
    final String dbFolder = platformParams.path;
    sqlite3Path = p.join(dbFolder, 'colla_chat.db');
    if (platformParams.mobile) {
      orientation = Orientation.portrait;
    } else {
      orientation = Orientation.landscape;
    }
  }

  /// 根据totalSize重新计算bodyWidth
  calBodyWidth() {
    double totalBodyWidth = portraitSize.width;
    double secondaryBodyWidth = portraitSize.width;
    double bodyWidth;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        totalBodyWidth = _totalSize.width - primaryNavigationWidth;
        secondaryBodyWidth = totalBodyWidth * 0.65;
        bodyWidth = totalBodyWidth - secondaryBodyWidth;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        totalBodyWidth = _totalSize.width - mediumPrimaryNavigationWidth;
        secondaryBodyWidth = totalBodyWidth * 0.5;
        bodyWidth = totalBodyWidth - secondaryBodyWidth;
      } else {
        secondaryBodyWidth = portraitSize.width;
        bodyWidth = totalBodyWidth - secondaryBodyWidth;
      }
      if (secondaryBodyWidth < portraitSize.width) {
        secondaryBodyWidth = portraitSize.width;
        bodyWidth = totalBodyWidth - secondaryBodyWidth;
      }
      if (bodyWidth < 0) {
        bodyWidth = 0;
      }
    } else {
      secondaryBodyWidth = _totalSize.width;
      bodyWidth = 0;
    }
    _bodyWidth = bodyWidth;
  }

  ///总的屏幕尺寸
  Size get totalSize {
    return _totalSize;
  }

  Size get designSize {
    //特殊效果的尺寸，宽度最大是390，高度最大是844
    return _designSize;
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

  /// 计算实际的主视图宽度，在竖屏的情况下始终为0，
  double get secondaryBodyWidth {
    double width = portraitSize.width;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        width = _totalSize.width - primaryNavigationWidth;
        width = width - _bodyWidth;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        width = _totalSize.width - mediumPrimaryNavigationWidth;
        width = width - _bodyWidth;
      } else {
        width = portraitSize.width;
      }
    } else {
      width = _totalSize.width;
    }

    return width;
  }

  double get bodyRatio {
    double width = portraitSize.width;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        width = _totalSize.width - primaryNavigationWidth;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        width = _totalSize.width - mediumPrimaryNavigationWidth;
      } else {
        return 0.0;
      }
    } else {
      return 0.0;
    }

    return _bodyWidth / width;
  }

  set secondBodyWidth(double secondBodyWidth) {
    if (secondBodyWidth < 0) {
      return;
    }
    if (secondBodyWidth < _designSize.width) {
      return;
    }
    double width = portraitSize.width;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        width = _totalSize.width - primaryNavigationWidth;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        width = _totalSize.width - mediumPrimaryNavigationWidth;
      }
    }
    double bodyWidth = width - secondBodyWidth;
    if (bodyWidth < 0) {
      bodyWidth = 0.0;
    }
    if (_bodyWidth != bodyWidth) {
      _bodyWidth = bodyWidth;
      notifyListeners();
    }
  }

  /// 设置bodyWidth，当设置的值为-1的时候重新计算bodyWidth
  set bodyWidth(double bodyWidth) {
    if (bodyWidth == -1) {
      calBodyWidth();
      notifyListeners();

      return;
    }
    if (bodyWidth < smallBreakpointLimit / 2) {
      bodyWidth = 0;
    }
    double width = portraitSize.width;
    if (landscape) {
      if (_totalSize.width >= largeBreakpointLimit) {
        width = _totalSize.width - primaryNavigationWidth;
      } else if (_totalSize.width >= smallBreakpointLimit) {
        width = _totalSize.width - mediumPrimaryNavigationWidth;
      }
    }
    if (width < bodyWidth) {
      return;
    }
    if (_bodyWidth != bodyWidth) {
      _bodyWidth = bodyWidth;
      notifyListeners();
    }
  }

  /// 计算实际的当前视图宽度
  double get bodyWidth {
    return _bodyWidth;
  }

  /// 二级视图是否横屏
  bool get secondaryBodyLandscape {
    return secondaryBodyWidth > _totalSize.height;
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
    var bottom = MediaQuery.viewInsetsOf(context).bottom;
    if (_keyboardHeight == 270.0 && bottom != 0) {
      _keyboardHeight = bottom;
      // logger.i('KeyboardHeight: $_keyboardHeight');
    }
    // logger.i('bottomBarHeight: $bottomBarHeight');
    // logger.i('toolbarHeight: $toolbarHeight');
    // 上下边距 （主要用于 刘海  和  内置导航键）
    topPadding = MediaQuery.paddingOf(context).top;
    // logger.i('topPadding: $topPadding');
    bottomPadding = MediaQuery.paddingOf(context).bottom;
    // logger.i('bottomPadding: $bottomPadding');

    textScaler = MediaQuery.textScalerOf(context);
    // logger.i('textScaleFactor: $textScaleFactor');

    var totalSize = MediaQuery.sizeOf(context);
    if (totalSize.width != _totalSize.width ||
        totalSize.height != _totalSize.height) {
      _totalSize = totalSize;
      if (_bodyWidth != 0) {
        calBodyWidth();
      }
    }
  }
}

final AppDataProvider appDataProvider = AppDataProvider();
