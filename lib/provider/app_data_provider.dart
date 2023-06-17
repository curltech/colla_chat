import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';

/// 不同语言版本的下拉选择框的选项
final localeOptions = [
  Option('English', LocaleUtil.getLocale('en_US')),
  Option('中文', LocaleUtil.getLocale('zh_CN')),
  Option('繁体中文', LocaleUtil.getLocale('zh_TW')),
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
  double leftBarWidth = 100;
  double mainViewWidth = 300;
  double dividerWidth = 1;
  double topPadding = 0;
  double bottomPadding = 0;
  double textScaleFactor = 1.0;
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

  ///竖屏尺寸，在竖屏的情况下，等于总尺寸，
  ///在横屏的情况下，用于登录等小页面的尺寸，露出后面的背景图像，等于竖屏设计尺寸与实际尺寸取较小值
  ///宽度必须小于450
  Size get portraitSize {
    double width = _totalSize.width;
    double height = _totalSize.height;
    //横屏需要根据固定的尺寸来计算
    if (landscape || (!landscape && _totalSize.width > 450)) {
      width = _totalSize.width < designSize.width
          ? _totalSize.width
          : designSize.width;
      height = _totalSize.height < designSize.height
          ? _totalSize.height
          : designSize.height;
      //高度还要减去底部工具栏的高度
      // height = height - bottomBarHeight;
    }

    return Size(width, height);
  }

  ///横屏，宽度大于高度并且宽度大于左边菜单宽度加上2个主视图宽度
  bool get landscape {
    return _totalSize.height < _totalSize.width &&
        _totalSize.width > (dividerWidth + leftBarWidth + mainViewWidth * 2);
  }

  ///计算实际的主视图宽度
  double get actualMainViewWidth {
    if (mainViewWidth == 0.0) {
      return 0.0;
    }
    double width = portraitSize.width;
    if (landscape) {
      width = (totalSize.width - leftBarWidth) / 3;
      if (width < mainViewWidth) {
        width = mainViewWidth;
      }
    }
    return width;
  }

  toggleMainView() {
    if (mainViewWidth == 0.0) {
      mainViewWidth = 300.0;
    } else {
      mainViewWidth = 0.0;
    }
    notifyListeners();
  }

  ///计算实际的当前视图宽度
  double get actualCurrentViewWidth {
    double width = portraitSize.width;
    if (landscape) {
      width =
          totalSize.width - leftBarWidth - actualMainViewWidth - dividerWidth;
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
      logger.i('Total size: $_totalSize');
    }
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    if (_keyboardHeight == 270.0 && bottom != 0) {
      _keyboardHeight = bottom;
      logger.i('KeyboardHeight: $_keyboardHeight');
    }
    logger.i('bottomBarHeight: $bottomBarHeight');
    logger.i('toolbarHeight: $toolbarHeight');
    // 上下边距 （主要用于 刘海  和  内置导航键）
    topPadding = MediaQuery.of(context).padding.top;
    logger.i('topPadding: $topPadding');
    bottomPadding = MediaQuery.of(context).padding.bottom;
    logger.i('bottomPadding: $bottomPadding');

    textScaleFactor = MediaQuery.of(context).textScaleFactor;
    logger.i('textScaleFactor: $textScaleFactor');
  }
}

var appDataProvider = AppDataProvider();
