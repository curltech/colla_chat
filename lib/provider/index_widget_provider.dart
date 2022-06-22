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

  ///存放元素的上一个元素
  final Map<T, T> _stacks = {};

  T? get head {
    return _head;
  }

  T? push(T element) {
    if (_head != null) {
      _stacks[element] = _head as T;
    }
    _head = element;
    return _stacks[_head];
  }

  T? pushRepeat(T element) {
    if (_head == null) {
      return push(element);
    }
    if (_head == element) {
      return _head;
    }
    T? current = _head;
    T? next;
    bool found = false;
    while (current != null) {
      T? pre = _stacks[current];
      if (current == element) {
        found = true;
        if (next != null && pre != null) {
          _stacks[next] = pre;
        }
        if (next != null && pre == null) {
          _stacks.remove(next);
        }
        if (_head != null) {
          _stacks[element] = _head as T;
        }
        _head = element;

        return _stacks[_head];
      }
      next = current;
      current = pre;
    }
    if (!found) {
      return push(element);
    }

    return null;
  }

  T? pop() {
    if (_head != null) {
      T? pre = _stacks[_head];
      if (pre != null) {
        _head = pre;
      } else {
        _head = null;
      }
      return _head;
    }
    return null;
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
      for (var i = 0; i < widgetPosition.length; ++i) {
        if (name == widgetPosition[i]) {
          _mainIndex = i;
          routeStyle = RouteStyle.workspace;
          break;
        }
      }
      routeStyle ??= _getRouteStyle(context: context, routeStyle: routeStyle);
      if (routeStyle == RouteStyle.workspace) {
        if (stack.head != name) {
          stack.pushRepeat(name);
          notifyListeners();
        }
      } else if (context != null) {
        jumpTo(name, context: context, routeStyle: routeStyle);
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
    routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
    if (routeStyle == RouteStyle.workspace) {
      if (viewPosition.containsKey(name)) {
        if (stack.head != name) {
          stack.pushRepeat(name);
          jumpTo(name, context: context, routeStyle: routeStyle);
        }
      }
    } else if (context != null) {
      jumpTo(name, context: context, routeStyle: routeStyle);
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
    routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
    if (routeStyle == RouteStyle.workspace) {
      stack.pop();
      String? head = stack.head;
      if (head != null) {
        jumpTo(head);
      }
    } else if (context != null) {
      NavigatorUtil.goBack(context);
    }
  }

  ///判断是否有可弹出的视图
  bool canPop({BuildContext? context, RouteStyle? routeStyle}) {
    routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
    if (routeStyle == RouteStyle.workspace) {
      return stack.canPop();
    } else if (context != null) {
      return NavigatorUtil.canBack(context);
    }
    return false;
  }

  ///直接跳转到位置的视图
  jumpToPage(int index) {
    if (index > -1 && _pageController != null && index < views.length) {
      try {
        _pageController!.jumpToPage(index);
      } catch (e) {
        logger.e('error:$e');
      }
    }
  }

  ///直接跳转到名字的视图
  jumpTo(String name, {BuildContext? context, RouteStyle? routeStyle}) {
    routeStyle = _getRouteStyle(context: context, routeStyle: routeStyle);
    if (routeStyle == RouteStyle.workspace) {
      int? index = viewPosition[name];
      if (index != null &&
          index > -1 &&
          index < views.length &&
          _pageController != null) {
        _pageController!.jumpToPage(index);
      }
    } else if (context != null) {
      NavigatorUtil.jump(context, '/$name');
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
