import 'package:flutter/material.dart';

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

  push(String name) {
    if (viewPosition.containsKey(name)) {
      stack.add(name);
      jumpTo(name);
    }
  }

  pop() {
    stack.removeLast();
    jumpTo(stack.last);
  }

  bool canPop() {
    return stack.isNotEmpty;
  }

  jumpToPage(int index) {
    if (_pageController != null) {
      _pageController!.jumpToPage(index);
    }
  }

  jumpTo(String name) {
    int? index = viewPosition[name];
    if (index != null) {
      if (index < views.length) {
        if (_pageController != null) {
          _pageController!.jumpToPage(index);
        }
      }
    }
  }

  @override
  dispose() {
    super.dispose();
    instance = IndexViewProvider();
  }
}
