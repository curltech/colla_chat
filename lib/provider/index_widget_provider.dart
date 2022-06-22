import 'package:colla_chat/routers/routes.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import '../l10n/localization.dart';
import '../routers/navigator_util.dart';
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

final List<String> widgetPosition = ['chat', 'linkman', 'channel', 'me'];

/// 主工作区的视图状态管理器，维护了主工作区的控制器，视图列表，当前视图
class IndexWidgetProvider with ChangeNotifier {
  static IndexWidgetProvider instance = IndexWidgetProvider();
  Map<String, int> viewPosition = {};
  List<Widget> views = [];
  Stack<String> stack = Stack<String>();
  static const String _head = '_head';
  PageController? _pageController;

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
  define(RouteNameMixin view, {bool listen = false}) {
    if (!viewPosition.containsKey(view.routeName)) {
      views.add(view);
      viewPosition[view.routeName] = views.length - 1;
      Application.router.define('/${view.routeName}', handler: Handler(
          handlerFunc:
              (BuildContext? context, Map<String, List<String>> params) {
        return view;
      }));
      if (listen) {
        notifyListeners();
      }
    }
  }

  String get current {
    String? head = stack.head;
    head ??= '';
    return head;
  }

  int get currentIndex {
    var head = current;
    if (head != '') {
      var index = viewPosition[head];
      index ??= -1;
      return index;
    } else {
      return -1;
    }
  }

  setCurrentIndex(int index, {BuildContext? context, RouteStyle? routeStyle}) {
    String? name;
    for (var entry in viewPosition.entries) {
      if (entry.value == index) {
        name = entry.key;
        break;
      }
    }
    if (name != null) {
      bool needNotify = false;
      for (var i = 0; i < widgetPosition.length; ++i) {
        if (name == widgetPosition[i] && _mainIndex != i) {
          _mainIndex = i;
          needNotify = true;
          break;
        }
      }
      if (stack.head != name) {
        stack.pushRepeat(name);
        routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
        if (RouteStyle.navigator == routeStyle && context != null) {
          _jumpTo(name, context: context, routeStyle: routeStyle);
        }
      }
      if (needNotify) {
        notifyListeners();
      }
    }
  }

  int get mainIndex {
    return _mainIndex;
  }

  set mainIndex(int index) {
    if (index >= 0 && index < widgetPosition.length) {
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

  ///把名字压入堆栈，然后跳转
  push(String name, {BuildContext? context, RouteStyle? routeStyle}) {
    if (viewPosition.containsKey(name)) {
      if (stack.head != name) {
        stack.pushRepeat(name);
        _jumpTo(name, context: context, routeStyle: routeStyle);
      }
    }
  }

  RouteStyle _getRouteStyle({BuildContext? context, RouteStyle? routeStyle}) {
    if (routeStyle == null) {
      if (appDataProvider.mobile && context != null) {
        routeStyle = RouteStyle.navigator;
      } else {
        routeStyle = RouteStyle.workspace;
      }
    }
    return routeStyle;
  }

  ///弹出最新的，跳转到第二新的
  pop({BuildContext? context, RouteStyle? routeStyle}) {
    String? head = stack.head;
    var needNavigator = true;
    if (head != null) {
      for (var i = 0; i < widgetPosition.length; ++i) {
        if (head == widgetPosition[i]) {
          needNavigator = false;
          break;
        }
      }
    }
    stack.pop();
    head = stack.head;
    if (head != null) {
      _jumpTo(head);
    }
    if (!needNavigator) {
      return;
    }
    routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
    if (RouteStyle.navigator == routeStyle && context != null) {
      NavigatorUtil.goBack(context);
    }
  }

  ///判断是否有可弹出的视图
  bool canPop({BuildContext? context, RouteStyle? routeStyle}) {
    bool can = stack.canPop();
    routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
    if (RouteStyle.navigator == routeStyle && context != null) {
      if (can != NavigatorUtil.canBack(context)) {
        logger.e('error: workspace canPop != navigator canPop');
      }
    }
    return can;
  }

  ///直接跳转到名字的视图,不压栈
  _jumpTo(String name, {BuildContext? context, RouteStyle? routeStyle}) {
    int? index = viewPosition[name];
    if (index != null &&
        index > -1 &&
        index < views.length &&
        _pageController != null) {
      _pageController!.jumpToPage(index);
      var needNavigator = true;
      for (var i = 0; i < widgetPosition.length; ++i) {
        if (name == widgetPosition[i]) {
          needNavigator = false;
          break;
        }
      }
      if (!needNavigator) {
        return;
      }
      routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
      if (RouteStyle.navigator == routeStyle && context != null) {
        NavigatorUtil.jump(context, '/$name');
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
    String name = widgetPosition[index];
    name = name ?? '';
    String? label = widgetLabels[name];
    label = label ?? '';

    return label;
  }
}
