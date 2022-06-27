import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import '../l10n/localization.dart';
import '../routers/navigator_util.dart';
import '../routers/routes.dart';
import '../widgets/common/data_listtile.dart';
import '../widgets/common/widget_mixin.dart';
import 'app_data_provider.dart';

class Stack<T> {
  T? _head;

  ///存放元素的上一个元素,最后一个元素的上一个元素为null
  final Map<T, T?> _stacks = {};

  ///存放元素的下一个元素，,最早一个元素的下一个元素为null
  final Map<T, T?> _reverse = {};

  T? get head {
    return _head;
  }

  ///直接压栈，头变成新元素，返回原来的头
  T? push(T element) {
    var back = _head;
    if (element == back) {
      return null;
    }
    _stacks[element] = _head;
    _reverse[element] = null;
    if (back != null) {
      _reverse[back] = element;
    }
    _head = element;
    logger.i('head:$_head');
    logger.i('stacks:$_stacks');
    logger.i('reverse:$_reverse');

    return back;
  }

  ///不重复压栈，如果新元素不存在，直接压栈，
  ///如果存在，
  T? pushRepeat(T element) {
    //是头
    if (_head == element) {
      logger.i('head == new element,no change');
      return null;
    }
    if (!_stacks.containsKey(element)) {
      return push(element);
    }
    //更早的元素
    var pre = _stacks[element];
    //更晚的元素,新元素不是头，所以next不为null
    var next = _reverse[element];
    //更新的元素的的上一个是新元素的上一个
    if (next != null) {
      _stacks[next] = pre;
    }
    if (pre != null) {
      _reverse[pre] = next;
    }
    //新元素成为最晚的
    var back = _head;
    _stacks[element] = _head;
    if (back != null) {
      _reverse[back] = element;
    }
    _reverse[element] = null;
    _head = element;
    logger.i('head:$_head');
    logger.i('stacks:$_stacks');
    logger.i('reverse:$_reverse');

    return null;
  }

  T? pop() {
    if (_head == null) {
      return null;
    }
    T? pre = _stacks[_head];
    _stacks.remove(_head);
    _reverse.remove(_head);
    if (pre != null) {
      _head = pre;
      _reverse[pre] = null;
    } else {
      _head = null;
    }
    logger.i('head:$_head');
    logger.i('stacks:$_stacks');
    logger.i('reverse:$_reverse');
    return _head;
  }

  canPop() {
    return _head != null;
  }
}

final List<String> workspaceViews = ['chat', 'linkman', 'channel', 'me'];
final bool useNavigator = false;

/// 主工作区的视图状态管理器，维护了主工作区的控制器，视图列表，当前视图
class IndexWidgetProvider with ChangeNotifier {
  static IndexWidgetProvider instance = IndexWidgetProvider();
  Map<String, int> viewPosition = {};
  List<Widget> views = [];
  Stack<String> stack = Stack<String>();
  static const String _head = '_head';
  PageController? _pageController;

  int _currentIndex = 0;

  ///左边栏和底部栏的指示，范围0-3
  int _mainIndex = 0;

  double _leftBarWidth = 90;

  IndexWidgetProvider();

  PageController? get pageController {
    return _pageController;
  }

  set pageController(PageController? pageController) {
    _pageController = pageController;
    if (_pageController != null) {
      _pageController!.addListener(() {
        //currentIndex = pageController.page!.floor();
      });
    }
  }

  ///增加新的视图，不能在initState和build构建方法中调用listen=true，
  ///因为本方法会引起整个pageview视图的重新构建
  define(TileDataMixin view, {bool listen = false}) {
    int workspaceViewIndex = _workspaceViewIndex(view.routeName);
    if (workspaceViewIndex > -1 || !useNavigator || !appDataProvider.mobile) {
      if (!viewPosition.containsKey(view.routeName)) {
        views.add(view);
        viewPosition[view.routeName] = views.length - 1;
      }
    } else {
      Application.router.define('/${view.routeName}', handler: Handler(
          handlerFunc:
              (BuildContext? context, Map<String, List<String>> params) {
        return view;
      }));
    }
    if (listen) {
      notifyListeners();
    }
  }

  String get current {
    String? head = stack.head;
    head ??= '';
    return head;
  }

  int get currentIndex {
    return _currentIndex;
  }

  String? _getName(int index) {
    String? name;
    for (var entry in viewPosition.entries) {
      if (entry.value == index) {
        name = entry.key;
        break;
      }
    }
    return name;
  }

  setCurrentIndex(int index, {BuildContext? context}) {
    _currentIndex = index;
    String? name = _getName(index);
    if (name != null) {
      int workspaceViewIndex = _workspaceViewIndex(name);
      if (workspaceViewIndex > -1 && _mainIndex != workspaceViewIndex) {
        _mainIndex = workspaceViewIndex;
      }
      _jumpTo(name, context: context);
    } else {
      logger.e('index:$index no name,not exist');
    }
  }

  int get mainIndex {
    return _mainIndex;
  }

  set mainIndex(int index) {
    if (index >= 0 && index < workspaceViews.length) {
      _mainIndex = index;
      notifyListeners();
    }
  }

  double get leftBarWidth {
    return _leftBarWidth;
  }

  set leftBarWidth(double width) {
    if (width < 0) {
      width = 0;
    }
    _leftBarWidth = width;
    notifyListeners();
  }

  bool get bottomBarVisible {
    if (appDataProvider.mobile) {
      String? name = _getName(_currentIndex);
      if (name != null) {
        int workspaceViewIndex = _workspaceViewIndex(name);
        if (workspaceViewIndex > -1) {
          return true;
        } else {
          return false;
        }
      }
    }
    return false;
  }

  ///把名字压入堆栈，然后跳转
  push(String name, {BuildContext? context, RouteStyle? routeStyle}) {
    _jumpTo(name, isPush: true, context: context);
  }

  int _workspaceViewIndex(String name) {
    var index = -1;
    for (var i = 0; i < workspaceViews.length; ++i) {
      if (name == workspaceViews[i]) {
        index = i;
        break;
      }
    }
    return index;
  }

  ///弹出最新的，跳转到第二新的
  pop({BuildContext? context}) {
    String? head = stack.head;
    if (head != null) {
      int workspaceViewIndex = _workspaceViewIndex(head);
      if (workspaceViewIndex > -1 || !useNavigator || !appDataProvider.mobile) {
        stack.pop();
        head = stack.head;
        if (head != null) {
          _jumpTo(head);
        }
      } else {
        if (context != null) {
          NavigatorUtil.goBack(context);
        } else {
          logger.e('pop error, no context');
        }
      }
    } else if (useNavigator && appDataProvider.mobile) {
      if (context != null) {
        NavigatorUtil.goBack(context);
      } else {
        logger.e('pop error, no context');
      }
    }
  }

  ///判断是否有可弹出的视图
  bool canPop({BuildContext? context}) {
    bool can = false;
    String? head = stack.head;
    if (head != null) {
      int workspaceViewIndex = _workspaceViewIndex(head);
      if (workspaceViewIndex > -1 || !useNavigator || !appDataProvider.mobile) {
        can = stack.canPop();
      } else {
        if (context != null) {
          can = NavigatorUtil.canBack(context);
        } else {
          logger.e('pop error, no context');
        }
      }
    } else if (useNavigator && appDataProvider.mobile) {
      if (context != null) {
        can = NavigatorUtil.canBack(context);
      } else {
        logger.e('pop error, no context');
      }
    }
    return can;
  }

  ///直接跳转到名字的视图
  _jumpTo(String name, {bool isPush = false, BuildContext? context}) {
    int? index = viewPosition[name];
    var pageController = _pageController;
    if (index != null &&
        index > -1 &&
        index < views.length &&
        pageController != null) {
      int workspaceViewIndex = _workspaceViewIndex(name);
      if (workspaceViewIndex > -1 || !useNavigator || !appDataProvider.mobile) {
        if (viewPosition.containsKey(name)) {
          _currentIndex = index;
          if (isPush) {
            stack.pushRepeat(name);
          }
          pageController.jumpToPage(index);
          notifyListeners();
        } else {
          logger.e('$name error,not exist');
        }
      } else {
        if (context != null) {
          NavigatorUtil.jump(context, '/$name');
        } else {
          logger.e('jump to $name error, no context');
        }
      }
    }
  }

  Color? getIconColor(int index) {
    if (index == mainIndex) {
      return appDataProvider.themeData?.colorScheme.primary;
    } else {
      return Colors.grey;
    }
  }

  String getLabel(int index) {
    var widgetLabels = {
      'chat': AppLocalizations.instance.text('Chat'),
      'linkman': AppLocalizations.instance.text('Linkman'),
      'channel': AppLocalizations.instance.text('Channel'),
      'me': AppLocalizations.instance.text('Me'),
    };
    String name = workspaceViews[index];
    name = name ?? '';
    String? label = widgetLabels[name];
    label = label ?? '';

    return label;
  }
}
