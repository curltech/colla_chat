import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

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
  List<NavigationDestination> _buildNavigationDestination(
      IndexWidgetProvider indexWidgetProvider) {
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
          ),
        ));
      }
    }
    return destinations;
  }

  SlotLayout build(IndexWidgetProvider indexWidgetProvider) {
    final List<NavigationDestination> destinations =
        _buildNavigationDestination(indexWidgetProvider);
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        Breakpoints.small: SlotLayout.from(
          key: const Key('Bottom Navigation Small'),
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: (_) => AdaptiveScaffold.standardBottomNavigationBar(
            destinations: destinations,
            currentIndex: indexWidgetProvider.currentMainIndex,
            onDestinationSelected: (int index) {
              indexWidgetProvider.currentMainIndex = index;
            },
          ),
        )
      },
    );
  }
}

final BottomNavigation bottomNavigation = BottomNavigation();
