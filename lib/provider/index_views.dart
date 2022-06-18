import 'package:flutter/material.dart';

import '../widgets/common/widget_mixin.dart';
import 'app_data.dart';

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

class IndexViewProvider with ChangeNotifier {
  static IndexViewProvider instance = IndexViewProvider();
  Map<String, int> viewPosition = {};
  List<Widget> views = [];
  Stack<String> stack = Stack<String>();
  static const String _head = '_head';
  PageController? _pageController;

  IndexViewProvider();

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

  ///增加新的视图，不能在build构建方法中调用，因为本方法会引起整个pageview视图的重新构建
  define(RouteNameMixin view) {
    if (!viewPosition.containsKey(view.routeName)) {
      views.add(view);
      viewPosition[view.routeName] = views.length - 1;
      notifyListeners();
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

  set currentIndex(int index) {
    for (var entry in viewPosition.entries) {
      if (entry.value == index) {
        var current_ = entry.key;
        if (stack.head != current_) {
          stack.pushRepeat(current_);
          notifyListeners();
        }
        break;
      }
    }
  }

  ///把名字压入堆栈，然后跳转
  push(String name) {
    if (viewPosition.containsKey(name)) {
      if (stack.head != name) {
        stack.pushRepeat(name);
        jumpTo(name);
      }
    }
  }

  ///弹出最新的，跳转到第二新的
  pop() {
    stack.pop();
    String? head = stack.head;
    if (head != null) {
      jumpTo(head);
    }
  }

  ///判断是否有可弹出的视图
  bool canPop() {
    return stack.canPop();
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
  jumpTo(String name) {
    int? index = viewPosition[name];
    if (index != null &&
        index > -1 &&
        index < views.length &&
        _pageController != null) {
      _pageController!.jumpToPage(index);
    }
  }

  @override
  dispose() {
    super.dispose();
    instance = IndexViewProvider();
  }
}
