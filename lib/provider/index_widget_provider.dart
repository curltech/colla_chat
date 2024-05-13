import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

const animateDuration = Duration(milliseconds: 1000);

/// 主工作区的视图状态管理器，维护了主工作区的控制器，视图列表，当前视图
class IndexWidgetProvider with ChangeNotifier {
  //所以可以出现在工作区的视图，开始序号是是主视图，其余是副视图，
  Map<String, TileDataMixin> allViews = {};

  ///主菜单和对应的主视图
  final List<String> mainViews = [];

  ///当前出现在工作区的视图，mainViews是主视图，始终都在，然后每进入一个新视图，则添加
  ///每退出一个则删除，
  List<TileDataMixin> views = [];
  List<TileDataMixin> recentViews = [];

  SwiperController? controller;

  //当前的主视图，左边栏和底部栏的指示，范围0-mainViews.length-1
  int _currentMainIndex = 0;
  bool grid = false;

  IndexWidgetProvider();

  ///初始化主菜单视图
  initMainView(SwiperController controller, List<TileDataMixin> views) {
    this.controller = controller;
    for (TileDataMixin view in views) {
      define(view);
      mainViews.add(view.routeName);
      this.views.add(view);
    }
  }

  addMainView(String routeName) {
    if (!mainViews.contains(routeName) && allViews.containsKey(routeName)) {
      mainViews.add(routeName);
      notifyListeners();
    }
  }

  removeMainView(String routeName) {
    if (mainViews.contains(routeName)) {
      mainViews.remove(routeName);
      notifyListeners();
    }
  }

  ///增加新的视图，不能在initState和build构建方法中调用listen=true，
  ///因为本方法会引起整个pageview视图的重新构建
  define(TileDataMixin view, {bool listen = false}) {
    allViews[view.routeName] = view;
    if (listen) {
      notifyListeners();
    }
  }

  ///当前的副视图名称
  String? get current {
    if (views.length > mainViews.length) {
      String routeName = views.last.routeName;

      return routeName;
    }

    return null;
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
      if (views.length > mainViews.length) {
        views.removeRange(mainViews.length, views.length);
      }
      //controller.jumpToPage(index);
      controller.move(index);
      notifyListeners();
    }
  }

  ///当前视图的序号
  int get currentIndex {
    return views.length - 1;
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
    TileDataMixin? view = allViews[name];
    if (view == null) {
      logger.e('view: $name is not exist');
      return;
    }
    if (mainViews.contains(name)) {
      logger.e('mainview: $name can not be push stack');
      return;
    }

    var controller = this.controller;
    if (controller == null) {
      logger.e('swiperController is not exist');
      return;
    }
    //判断要进入的页面是否已在工作区
    int index = views.indexOf(view);
    if (index == -1) {
      //不是主页面，增加到工作区
      views.add(view);
      index = views.length - 1;
    }
    if (index < allViews.length) {
      controller.move(index);
      TileDataMixin mixin = views[index];
      if (!recentViews.contains(mixin)) {
        if (recentViews.length > 5) {
          recentViews.removeAt(0);
        }
        recentViews.add(views[index]);
      }

      notifyListeners();
    }
  }

  ///弹出最新的，跳转到第二新的
  pop({BuildContext? context}) {
    // if (popAction) {
    //   popAction = false;
    //   return;
    // }
    var controller = this.controller;
    if (controller == null) {
      logger.e('swiperController is not exist');
      return;
    }

    //堆栈有头视图，可以弹出
    int index = views.length - 1;
    //头视图在工作区内
    if (index >= mainViews.length) {
      views.removeLast();
      index = views.length - 1;
      if (index < mainViews.length) {
        index = _currentMainIndex;
      }
      controller.move(index);
      notifyListeners();
    }
  }

  Color? getIconColor(int index) {
    if (index == currentMainIndex) {
      return myself.primary;
    } else {
      return Colors.grey;
    }
  }

  String getLabel(int index) {
    String name = mainViews[index];
    TileDataMixin? widget = allViews[name];
    if (widget != null) {
      return AppLocalizations.t(widget.title ?? '');
    }
    return '';
  }
}

final IndexWidgetProvider indexWidgetProvider = IndexWidgetProvider();
