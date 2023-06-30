import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
      {String? label, String? tooltip}) {
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

  Widget _createLeadingButton() {
    return ValueListenableBuilder(
        valueListenable: mainViewVisible,
        builder: (BuildContext context, bool mainViewVisible, Widget? child) {
          return IconButton(
              onPressed: () {
                this.mainViewVisible.value = !this.mainViewVisible.value;
                appDataProvider.toggleBody();
              },
              icon: mainViewVisible
                  ? const Icon(Icons.menu_open)
                  : const Icon(Icons.menu_book));
        });
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
  List<NavigationRailDestination> _buildNavigationRailDestination(
      IndexWidgetProvider indexWidgetProvider) {
    List<NavigationRailDestination> destinations = [];
    double index = 0;
    for (String mainView in indexWidgetProvider.mainViews) {
      TileDataMixin? view = indexWidgetProvider.allViews[mainView];
      if (view != null) {
        destinations.add(slideInNavigationRailDestination(
          label: Text(AppLocalizations.t(view.title)),
          icon: Icon(view.iconData),
          selectedIcon: Icon(
            view.iconData,
            size: AppIconSize.mdSize,
          ),
          begin: -index,
          controller: _slideControllers[index.toInt()],
        ));
      }
      index++;
    }
    return destinations;
  }

  ///附属菜单按钮，用于大屏幕下侧边显示更多的菜单项
  Widget _buildTrailingNavRail() {
    return const SizedBox(
      width: 0.0,
      height: 0.0,
    );
  }

  /// Primary navigation，侧边栏，在小屏幕时为空， 中屏幕时为只有图标的菜单，大屏幕时为带文字的图标，且有附加菜单项
  SlotLayout build(IndexWidgetProvider indexWidgetProvider) {
    final List<NavigationRailDestination> destinations =
        _buildNavigationRailDestination(indexWidgetProvider);
    final Widget trailingNavRail = _buildTrailingNavRail();
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.mediumBreakpoint: SlotLayout.from(
            //inAnimation: AdaptiveScaffold.leftOutIn,
            key: const Key('Primary Navigation Medium'),
            //在布局中放置AdaptiveScaffold标准侧边栏
            builder: (_) {
              return AdaptiveScaffold.standardNavigationRail(
                width: appDataProvider.mediumPrimaryNavigationWidth,
                selectedIndex: indexWidgetProvider.currentMainIndex,
                onDestinationSelected: (int index) {
                  indexWidgetProvider.currentMainIndex = index;
                },
                padding: const EdgeInsets.all(0.0),
                leading: _createLeadingButton(),
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
              );
            }),
        appDataProvider.largeBreakpoint: SlotLayout.from(
            key: const Key('Primary Navigation Large'),
            //inAnimation: AdaptiveScaffold.leftOutIn,
            builder: (_) {
              return AdaptiveScaffold.standardNavigationRail(
                backgroundColor: Colors.black.withOpacity(0.0),
                width: appDataProvider.primaryNavigationWidth,
                selectedIndex: indexWidgetProvider.currentMainIndex,
                onDestinationSelected: (int index) {
                  indexWidgetProvider.currentMainIndex = index;
                },
                padding: const EdgeInsets.all(0.0),
                leading: _createLeadingButton(),
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
              );
            }),
      },
    );
  }

  dispose() {
    for (var slideController in _slideControllers) {
      slideController.dispose();
    }
  }
}

final PrimaryNavigation primaryNavigation = PrimaryNavigation();
