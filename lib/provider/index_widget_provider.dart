import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/navigator_util.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class ViewStack<T> {
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
    // logger.i('head:$_head');
    // logger.i('stacks:$_stacks');
    // logger.i('reverse:$_reverse');

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
    // logger.i('head:$_head');
    // logger.i('stacks:$_stacks');
    // logger.i('reverse:$_reverse');
    return _head;
  }

  canPop() {
    return _head != null;
  }
}

///主菜单和对应的主视图
final List<String> mainViews = ['chat', 'linkman', 'channel', 'me'];
const bool useNavigator = false;
const animateDuration = Duration(milliseconds: 500);

/// 主工作区的视图状态管理器，维护了主工作区的控制器，视图列表，当前视图
class IndexWidgetProvider with ChangeNotifier {
  //所以可以出现在工作区的视图，0-3是主视图，其余是副视图，
  Map<String, Widget> allViews = {};

  ///当前出现在工作区的视图，0-3是主视图，始终都在，然后每进入一个新视图，则添加
  ///每退出一个则删除，
  List<Widget> views = [];

  ///前出现在工作区的视图views名称和位置的映射
  Map<String, int> viewPositions = {};

  //只有副视图才存储出现在堆栈中
  ViewStack<String> stack = ViewStack<String>();
  PageController? controller;

  //当前的主视图，左边栏和底部栏的指示，范围0-3
  int _currentMainIndex = 0;

  int _currentIndex = 0;

  bool popAction = false;

  IndexWidgetProvider() {
    //初始化主视图，确定好主视图的位置
    for (var i = 0; i < mainViews.length; ++i) {
      String name = mainViews[i];
      allViews[name] = Container();
      views.add(Container());
      viewPositions[name] = i;
    }
  }

  ///增加新的视图，不能在initState和build构建方法中调用listen=true，
  ///因为本方法会引起整个pageview视图的重新构建
  define(TileDataMixin view, {bool listen = false}) {
    if (!useNavigator || !platformParams.mobile) {
      allViews[view.routeName] = view;
      int? viewIndex = viewPositions[view.routeName];
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

  ///当前的副视图名称
  String? get current {
    String? head = stack.head;
    return head;
  }

  ///当前主视图的序号
  int get currentMainIndex {
    return _currentMainIndex;
  }

  set currentMainIndex(int index) {
    if (_currentMainIndex == index) {
      return;
    }
    if (index >= 0 && index < mainViews.length) {
      _currentMainIndex = index;
      var controller = this.controller;
      if (controller == null) {
        logger.e('swiperController is not exist');
        return;
      }
      //controller.jumpToPage(index);
      controller.animateToPage(index,
          duration: animateDuration, curve: Curves.easeInOut);
      notifyListeners();
    }
  }

  ///当前视图的序号
  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int index) {
    if (_currentIndex == index) {
      return;
    }
    //logger.i('popAction:$popAction,move view from $currentIndex to $index');
    if (_currentIndex > 3 &&
        index < _currentIndex &&
        viewPositions.length > 4 &&
        !popAction) {
      pop();
    }
    if (popAction) {
      popAction = false;
    }
    _currentIndex = index;
  }

  bool get bottomBarVisible {
    if (current == null) {
      return true;
    } else {
      return false;
    }
  }

  ///把名字压入堆栈，然后跳转
  push(String name, {bool push = true, BuildContext? context}) {
    //判断要进入的页面是否存在
    Widget? view = allViews[name];
    if (view == null) {
      logger.e('view: $name is not exist');
      return;
    }
    for (var mainName in mainViews) {
      if (mainName == name) {
        logger.e('mainview: $name can not be push stack');
        return;
      }
    }
    //桌面工作区模式
    if (!useNavigator || !platformParams.mobile) {
      var controller = this.controller;
      if (controller == null) {
        logger.e('swiperController is not exist');
        return;
      }
      //判断要进入的页面是否已在工作区
      int? index = viewPositions[name];
      if (index == null) {
        //不是主页面，增加到工作区
        views.add(view);
        index = views.length - 1;
        viewPositions[name] = index;
      }
      if (index < allViews.length) {
        if (push) {
          stack.pushRepeat(name);
        }
        controller.animateToPage(index,
            duration: animateDuration, curve: Curves.easeInOut);
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
    int? index = viewPositions[head];
    //头视图在工作区内
    if (index != null) {
      //堆栈头视图不是主视图，可以弹出，计算弹出后的视图
      if (index >= mainViews.length) {
        //否则弹出后跳转
        stack.pop();
        String name = head;
        head = stack.head;
        if (head != null) {
          index = viewPositions[head];
        } else {
          index = _currentMainIndex;
        }
        index ??= _currentMainIndex;
        views.removeLast();
        viewPositions.remove(name);
        popAction = true;
      }
    } else {
      logger.e('head is not in workspace');
    }
    return index;
  }

  ///弹出最新的，跳转到第二新的
  pop({BuildContext? context}) {
    //桌面工作区模式
    if (!useNavigator || !platformParams.mobile) {
      var controller = this.controller;
      if (controller == null) {
        logger.e('swiperController is not exist');
        return;
      }

      int? index = _pop();
      if (index != null) {
        controller.animateToPage(index,
            duration: animateDuration, curve: Curves.easeInOut);
        notifyListeners();
      }
    } else {
      if (context != null) {
        NavigatorUtil.goBack(context);
        popAction = true;
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
      return true;
    } else if (useNavigator && platformParams.mobile) {
      if (context != null) {
        can = NavigatorUtil.canBack(context);
      } else {
        logger.e('pop error, no context');
      }
    }
    return can;
  }

  Color? getIconColor(int index) {
    if (index == currentMainIndex) {
      return myself.primary;
    } else {
      return Colors.grey;
    }
  }

  String getLabel(int index) {
    var widgetLabels = {
      'chat': AppLocalizations.t('Chat'),
      'linkman': AppLocalizations.t('Linkman'),
      'channel': AppLocalizations.t('Channel'),
      'me': AppLocalizations.t('Me'),
    };
    String name = mainViews[index];
    String? label = widgetLabels[name];
    label = label ?? '';

    return label;
  }
}

final IndexWidgetProvider indexWidgetProvider = IndexWidgetProvider();
