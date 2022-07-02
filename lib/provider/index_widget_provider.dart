import 'package:colla_chat/widgets/common/blank_widget.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import '../l10n/localization.dart';
import '../routers/navigator_util.dart';
import '../routers/routes.dart';
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

final List<String> mainViews = ['chat', 'linkman', 'channel', 'me'];
final bool useNavigator = false;

/// 主工作区的视图状态管理器，维护了主工作区的控制器，视图列表，当前视图
class IndexWidgetProvider with ChangeNotifier {
  static IndexWidgetProvider instance = IndexWidgetProvider();

  ///所有视图名称和位置的映射
  Map<String, int> viewPosition = {};

  ///所以可以出现在工作区的视图，0-3是主视图
  Map<String, Widget> allViews = {};

  ///当前出现在工作区的视图，0-3是主视图，始终都在，然后每进入一个新视图，则添加
  ///每退出一个则删除
  List<Widget> views = [];
  Stack<String> stack = Stack<String>();
  PageController? pageController;
  int _currentIndex = 0;

  ///左边栏和底部栏的指示，范围0-3
  int _mainIndex = 0;
  double _leftBarWidth = 90;

  IndexWidgetProvider() {
    for (var i = 0; i < mainViews.length; ++i) {
      String name = mainViews[i];
      allViews[name] = blankWidget;
      views.add(blankWidget);
      viewPosition[name] = i;
    }
  }

  ///增加新的视图，不能在initState和build构建方法中调用listen=true，
  ///因为本方法会引起整个pageview视图的重新构建
  define(TileDataMixin view, {bool listen = false}) {
    if (!useNavigator || !appDataProvider.mobile) {
      allViews[view.routeName] = view;
      int? viewIndex = viewPosition[view.routeName];
      if (viewIndex != null && viewIndex < mainViews.length) {
        views[viewIndex] = view;
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

  int get mainIndex {
    return _mainIndex;
  }

  set mainIndex(int index) {
    if (index >= 0 && index < mainViews.length) {
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
      if (_currentIndex < mainViews.length) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  ///视图转换已经发生
  setCurrentIndex(int index, {BuildContext? context}) {
    if (_currentIndex == index) {
      return;
    }
    if (index >= views.length) {
      logger.e('index: $index over workspace view');
      return;
    }

    logger.i('mainIndex:$mainIndex;currentIndex:$_currentIndex;index:$index');
    //主视图转换到主视图，通知边栏和底栏
    if (_currentIndex < mainViews.length && index < mainViews.length) {
      if (_mainIndex != index) {
        _mainIndex = index;
      }
    }
    //非主视图转换到主视图
    else if (_currentIndex >= mainViews.length && index < mainViews.length) {
      _pop();
    }
    //非主视图转换到非主视图
    else if (_currentIndex >= mainViews.length && index >= mainViews.length) {
      _pop();
    }
    //主视图转换到非主视图
    else if (_currentIndex < mainViews.length && index >= mainViews.length) {}
    _currentIndex = index;
    notifyListeners();
  }

  ///把名字压入堆栈，然后跳转
  push(String name, {bool push = true, BuildContext? context}) {
    //判断要进入的页面是否存在
    Widget? view = allViews[name];
    if (view == null) {
      logger.e('view: $name is not exist');
      return;
    }
    //桌面工作区模式
    if (!useNavigator || !appDataProvider.mobile) {
      var pageController = this.pageController;
      if (pageController == null) {
        logger.e('pageController is not exist');
        return;
      }
      //判断要进入的页面是否已在工作区
      int? index = viewPosition[name];
      if (index == null) {
        //不是主页面，增加到工作区
        views.add(view);
        index = views.length - 1;
        viewPosition[name] = index;
      } else {
        if (_currentIndex == index) {
          return;
        }
      }
      if (index < allViews.length) {
        _currentIndex = index;
        if (push) {
          stack.pushRepeat(name);
        }
        pageController.jumpToPage(index);
        // pageController.animateToPage(index,
        //     duration: const Duration(milliseconds: 100),
        //     curve: Curves.easeInOut);
        notifyListeners();
      } else {
        logger.e('$name error,not exist');
      }
    } else {
      //移动版路由模式
      if (context != null) {
        NavigatorUtil.jump(context, '/$name');
      } else {
        logger.e('jump to $name error, no context');
      }
    }
  }

  ///堆栈弹出，然后计算弹出堆栈后要跳转的视图
  int? _pop() {
    String? head = stack.head;
    if (head == null) {
      logger.i('head is null');
      return null;
    }
    //堆栈有头视图，可以弹出
    int? index = viewPosition[head];
    //头视图在工作区内
    if (index != null) {
      //堆栈头视图不是主视图，可以弹出，计算弹出后的视图
      if (index >= mainViews.length) {
        //否则弹出后跳转
        stack.pop();
        String name = head;
        head = stack.head;
        if (head != null) {
          index = viewPosition[head];
        } else {
          index = _mainIndex;
        }
        index ??= _mainIndex;
        views.removeLast();
        viewPosition.remove(name);
      }
    } else {
      logger.e('head is not in workspace');
    }
    return index;
  }

  ///弹出最新的，跳转到第二新的
  pop({BuildContext? context}) {
    //桌面工作区模式
    if (!useNavigator || !appDataProvider.mobile) {
      var pageController = this.pageController;
      if (pageController == null) {
        logger.e('pageController is not exist');
        return;
      }

      int? index = _pop();
      if (index != null) {
        pageController.jumpToPage(index);
        _currentIndex = index;
        notifyListeners();
      }
    } else {
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
      int? viewIndex = viewPosition[head];
      if (viewIndex != null) {
        if (viewIndex >= mainViews.length ||
            !useNavigator ||
            !appDataProvider.mobile) {
          can = stack.canPop();
        }
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
    String name = mainViews[index];
    name = name ?? '';
    String? label = widgetLabels[name];
    label = label ?? '';

    return label;
  }
}
