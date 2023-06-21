import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';

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
    return <NavigationDestination>[
      NavigationDestination(
        label: indexWidgetProvider.getLabel(0),
        icon: const Icon(Icons.chat),
        selectedIcon: const Icon(Icons.chat),
      ),
      NavigationDestination(
        label: indexWidgetProvider.getLabel(1),
        icon: const Icon(Icons.contacts),
        selectedIcon: const Icon(Icons.contacts),
      ),
      NavigationDestination(
        label: indexWidgetProvider.getLabel(2),
        icon: const Icon(Icons.wifi_channel),
        selectedIcon: const Icon(Icons.wifi_channel),
      ),
      NavigationDestination(
        label: indexWidgetProvider.getLabel(3),
        icon: const Icon(Icons.person),
        selectedIcon: const Icon(Icons.person),
      ),
    ];
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
