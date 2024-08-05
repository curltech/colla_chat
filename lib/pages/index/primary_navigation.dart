import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

///横屏左边栏，用于指示当前主页面
class PrimaryNavigation {
  ValueNotifier<bool> mainViewVisible = ValueNotifier<bool>(true);

  // 主菜单项对应的动画控制器
  final List<AnimationController> _slideControllers = [];

  initController(TickerProvider vsync) {
    int index = 0;
    for (String mainView in indexWidgetProvider.mainViews) {
      TileDataMixin? view = indexWidgetProvider.allViews[mainView];
      if (view != null) {
        _slideControllers.add(AnimationController(
          duration: Duration(milliseconds: 100 + index * 20),
          vsync: vsync,
        )..forward());
      }
      index++;
    }
  }

  forward() {
    for (var slideController in _slideControllers) {
      slideController.forward();
    }
  }

  Widget _createNavigationDestinationItem(
      IndexWidgetProvider indexWidgetProvider, int index, Icon icon,
      {String? label}) {
    bool current = indexWidgetProvider.currentMainIndex == index;
    List<Widget> children = [icon];
    if (label != null) {
      children.add(CommonAutoSizeText(
        label,
        style: TextStyle(
            color: current ? myself.primary : Colors.grey,
            fontSize: current ? AppFontSize.mdFontSize : AppFontSize.smFontSize,
            fontWeight: current ? FontWeight.bold : FontWeight.normal),
      ));
    }
    Widget item = SizedBox(
      height: 100,
      child: Column(children: children),
      // child: IconButton(
      //   iconSize: current ? AppIconSize.mdSize : AppIconSize.smSize,
      //   color: current ? myself.primary : Colors.grey,
      //   onPressed: null,
      //   icon: Column(children: children),
      //   tooltip: tooltip,
      // )
    );

    return item;
  }

  Widget _buildAppBar(BuildContext context) {
    if (appDataProvider.smallBreakpoint.isActive(context)) {
      return nil;
    }

    Widget avatarImage = myself.avatarImage ?? AppImage.mdAppImage;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(
        color: Colors.white,
        onPressed: () {
          indexWidgetProvider.push('personal_info');
        },
        tooltip: myself.name,
        icon: avatarImage,
      ),
      IconButton(
          color: myself.primary,
          tooltip: AppLocalizations.t('Change body ratio'),
          onPressed: () {
            appDataProvider.changeBodyRatio();
          },
          icon: const Icon(Icons.width_wide_outlined)),
    ]);
  }

  NavigationRailDestination slideInNavigationRailDestination({
    required double begin,
    required AnimationController controller,
    required Widget icon,
    required Widget label,
    Widget? selectedIcon,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    EdgeInsetsGeometry? padding,
  }) {
    return NavigationRailDestination(
      icon: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(begin, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
        ),
        child: icon,
      ),
      label: label,
      selectedIcon: selectedIcon,
      indicatorColor: indicatorColor,
      indicatorShape: indicatorShape,
      padding: padding,
    );
  }

  ///大屏幕的primaryNavigation
  List<NavigationRailDestination> _buildNavigationRailDestination() {
    List<NavigationRailDestination> destinations = [];
    double index = 0;
    for (String mainView in indexWidgetProvider.mainViews) {
      TileDataMixin? view = indexWidgetProvider.allViews[mainView];
      if (view != null) {
        AnimationController slideController = _slideControllers[index.toInt()];
        destinations.add(slideInNavigationRailDestination(
          label: Text(AppLocalizations.t(view.title)),
          icon: Icon(view.iconData),
          padding: EdgeInsets.zero,
          selectedIcon: Icon(
            view.iconData,
            size: AppIconSize.mdSize,
            color: myself.primary,
          ),
          begin: -index,
          controller: slideController,
        ));
      }
      index++;
    }
    return destinations;
  }

  ///附属菜单按钮，用于大屏幕下侧边显示更多的菜单项
  Widget _buildTrailingNavRail() {
    var recentViews = indexWidgetProvider.recentViews;
    if (recentViews.isNotEmpty) {
      List<Widget> children = [
        const SizedBox(
          height: 30,
        )
      ];
      for (var view in recentViews) {
        var routeName = view.routeName;
        children.add(IconButton(
            onPressed: () {
              indexWidgetProvider.push(routeName);
            },
            icon: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              view.iconData is IconData
                  ? Icon(
                      view.iconData,
                      color: myself.primary,
                    )
                  : view.iconData,
              const SizedBox(
                width: 10.0,
              ),
              Expanded(
                  child: Text(
                AppLocalizations.t(view.title),
                style: const TextStyle(color: Colors.white),
              ))
            ])));
      }
      return Column(
          mainAxisAlignment: MainAxisAlignment.start, children: children);
    }
    return nilBox;
  }

  /// Primary navigation，侧边栏，在小屏幕时为空， 中屏幕时为只有图标的菜单，大屏幕时为带文字的图标，且有附加菜单项
  SlotLayout build() {
    final List<NavigationRailDestination> destinations =
        _buildNavigationRailDestination();
    final Widget trailingNavRail = _buildTrailingNavRail();
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.mediumBreakpoint: SlotLayout.from(
            //inAnimation: AdaptiveScaffold.leftOutIn,
            key: const Key('Primary Navigation Medium'),
            //在布局中放置AdaptiveScaffold标准侧边栏
            builder: (BuildContext context) {
              return Card(
                  elevation: 0.0,
                  color: Colors.black54,
                  shape: const ContinuousRectangleBorder(),
                  margin: EdgeInsets.zero,
                  child: AdaptiveScaffold.standardNavigationRail(
                    width: appDataProvider.mediumPrimaryNavigationWidth,
                    selectedIndex: indexWidgetProvider.currentMainIndex,
                    onDestinationSelected: (int index) {
                      indexWidgetProvider.currentMainIndex = index;
                    },
                    padding: const EdgeInsets.all(0.0),
                    backgroundColor: Colors.black54,
                    leading: _buildAppBar(context),
                    destinations: destinations,
                    selectedIconTheme: IconThemeData(
                      color: myself.primary,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      color: Colors.grey,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                        fontSize: AppFontSize.mdFontSize,
                        fontWeight: FontWeight.bold),
                    unSelectedLabelTextStyle: const TextStyle(
                      fontSize: AppFontSize.smFontSize,
                    ),
                  ));
            }),
        appDataProvider.largeBreakpoint: SlotLayout.from(
            key: const Key('Primary Navigation Large'),
            //inAnimation: AdaptiveScaffold.leftOutIn,
            builder: (BuildContext context) {
              return Card(
                  elevation: 0.0,
                  color: Colors.black54,
                  shape: const ContinuousRectangleBorder(),
                  margin: EdgeInsets.zero,
                  child: AdaptiveScaffold.standardNavigationRail(
                    width: appDataProvider.primaryNavigationWidth,
                    selectedIndex: indexWidgetProvider.currentMainIndex,
                    onDestinationSelected: (int index) {
                      indexWidgetProvider.currentMainIndex = index;
                    },
                    padding: const EdgeInsets.all(0.0),
                    backgroundColor: Colors.black54,
                    leading: _buildAppBar(context),
                    destinations: destinations,
                    extended: true,
                    trailing: trailingNavRail,
                    selectedIconTheme: IconThemeData(
                      color: myself.primary,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      color: Colors.grey,
                    ),
                    selectedLabelTextStyle: TextStyle(
                        color: myself.primary,
                        fontSize: AppFontSize.mdFontSize,
                        fontWeight: FontWeight.bold),
                    unSelectedLabelTextStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: AppFontSize.smFontSize,
                    ),
                  ));
            }),
      },
    );
  }

  dispose() {
    for (var slideController in _slideControllers) {
      slideController.dispose();
    }
    _slideControllers.clear();
  }
}
