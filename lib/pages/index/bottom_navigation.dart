import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/adaptive_scaffold/adaptive_scaffold.dart';
import 'package:colla_chat/widgets/adaptive_scaffold/breakpoints.dart';
import 'package:colla_chat/widgets/adaptive_scaffold/slot_layout.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/material.dart';

///mobile底边栏，用于指示当前主页面
class BottomNavigation {
  NavigationDestination _slideInNavigationDestination({
    required double begin,
    required AnimationController controller,
    required Widget icon,
    required String label,
    Widget? selectedIcon,
    String? tooltip,
  }) {
    return NavigationDestination(
      icon: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(begin, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
        ),
        child: icon,
      ),
      selectedIcon: selectedIcon,
      label: label,
      tooltip: tooltip,
    );
  }

  ///小屏幕的bottomNavigation
  List<NavigationDestination> _buildNavigationDestination() {
    List<NavigationDestination> destinations = [];
    for (String mainView in indexWidgetProvider.mainViews) {
      TileDataMixin? view = indexWidgetProvider.allViews[mainView];
      if (view != null) {
        destinations.add(NavigationDestination(
          label: AppLocalizations.t(view.title),
          icon: Icon(view.iconData),
          selectedIcon: Icon(
            view.iconData,
            size: AppIconSize.mdSize,
            color: myself.primary,
          ),
        ));
      }
    }
    return destinations;
  }

  Builder _standardBottomNavigationBar({
    required List<NavigationDestination> destinations,
    int? currentIndex,
    double iconSize = 24,
    ValueChanged<int>? onDestinationSelected,
  }) {
    return Builder(
      builder: (BuildContext context) {
        final navigationBar = NavigationBar(
          backgroundColor: myself.primary.withAlpha(15),
          selectedIndex: currentIndex ?? 0,
          destinations: destinations,
          onDestinationSelected: onDestinationSelected,
        );
        final NavigationBarThemeData currentNavBarTheme =
            NavigationBarTheme.of(context);
        return NavigationBarTheme(
          data: currentNavBarTheme.copyWith(
            labelTextStyle:
                WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              return currentNavBarTheme.labelTextStyle
                  ?.resolve(states)
                  ?.copyWith(color: Colors.white);
            }),
            iconTheme: WidgetStateProperty.resolveWith(
              (Set<WidgetState> states) {
                return currentNavBarTheme.iconTheme
                        ?.resolve(states)
                        ?.copyWith(size: iconSize) ??
                    IconTheme.of(context).copyWith(size: iconSize);
              },
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context)..removePadding(removeTop: true),
            child: navigationBar.asStyle(
                blur: 128, height: navigationBar.height ?? appDataProvider.bottomBarHeight),
          ),
        );
      },
    );
  }

  SlotLayout build() {
    final List<NavigationDestination> destinations =
        _buildNavigationDestination();
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.smallBreakpoint: SlotLayout.from(
          key: const Key('Bottom Navigation Small'),
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: (_) {
            return _standardBottomNavigationBar(
              destinations: destinations,
              currentIndex: indexWidgetProvider.currentMainIndex,
              onDestinationSelected: (int index) {
                indexWidgetProvider.currentMainIndex = index;
              },
            );
          },
        )
      },
    );
  }
}
