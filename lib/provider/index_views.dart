import 'package:flutter/material.dart';

import 'app_data.dart';

class IndexViewProvider with ChangeNotifier {
  static IndexViewProvider instance = IndexViewProvider();
  Map<String, int> viewPosition = {};
  List<Widget> views = [];
  List<String> stack = [];
  PageController? _pageController;
  String _current = 'chat';

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
  define(String name, Widget view) {
    if (!viewPosition.containsKey(name)) {
      views.add(view);
      viewPosition[name] = views.length - 1;
      notifyListeners();
    }
  }

  String get current {
    return _current;
  }

  set current(String current) {
    if (viewPosition.containsKey(current)) {
      _current = current;
      notifyListeners();
    }
  }

  int get currentIndex {
    var index = viewPosition[_current];
    index ??= -1;
    return index;
  }

  set currentIndex(int index) {
    for (var entry in viewPosition.entries) {
      if (entry.value == index) {
        var current_ = entry.key;
        _current = current_;
        notifyListeners();
        break;
      }
    }
  }

  ///把名字压入堆栈，然后跳转
  push(String name) {
    if (viewPosition.containsKey(name)) {
      stack.add(name);
      jumpTo(name);
    }
  }

  ///弹出最新的，跳转到第二新的
  pop() {
    if (stack.isNotEmpty) {
      stack.removeLast();
    }
    if (stack.isNotEmpty) {
      jumpTo(stack.last);
    }
  }

  ///判断是否有可弹出的视图
  bool canPop() {
    return stack.isNotEmpty;
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
