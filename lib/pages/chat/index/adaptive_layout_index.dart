import 'package:colla_chat/pages/chat/channel/subscribe_channel_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/index/bottom_navigation.dart';
import 'package:colla_chat/pages/chat/index/primary_navigation.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/me/me_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';

///自动适配的主页面结构
class AdaptiveLayoutIndex extends StatefulWidget {
  AdaptiveLayoutIndex({super.key}) {
    PageController controller = PageController();
    indexWidgetProvider.controller = controller;
    indexWidgetProvider.define(ChatListWidget());
    indexWidgetProvider.define(LinkmanListWidget());
    indexWidgetProvider.define(SubscribeChannelListWidget());
    indexWidgetProvider.define(MeWidget());
  }

  @override
  State<AdaptiveLayoutIndex> createState() => _AdaptiveLayoutIndexState();
}

class _AdaptiveLayoutIndexState extends State<AdaptiveLayoutIndex>
    with TickerProviderStateMixin {
  // 主菜单项对应的动画控制器
  late AnimationController _chatSlideController;
  late AnimationController _linkmanSlideController;
  late AnimationController _channelSlideController;
  late AnimationController _meSlideController;

  @override
  void initState() {
    appDataProvider.addListener(_update);
    _chatSlideController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..forward();
    _linkmanSlideController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    )..forward();
    _channelSlideController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    )..forward();
    _meSlideController = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    )..forward();
    super.initState();
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  ///Body视图
  Widget _buildBodyView() {
    //return indexWidgetProvider.views[indexWidgetProvider.currentMainIndex];
    return Row(children: [
      const VerticalDivider(
        width: 1.0,
      ),
      Expanded(
          child:
              indexWidgetProvider.views[indexWidgetProvider.currentMainIndex]),
      const VerticalDivider(
        width: 1.0,
      ),
    ]);
  }

  /// 放置Body
  SlotLayout? _buildBody() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.mediumBreakpoint: SlotLayout.from(
          key: const Key('Body Medium'),
          // inAnimation: AdaptiveScaffold.leftInOut,
          // outAnimation: AdaptiveScaffold.leftOutIn,
          builder: (_) => _buildBodyView(),
        ),
        appDataProvider.largeBreakpoint: SlotLayout.from(
          key: const Key('Body Large'),
          // inAnimation: AdaptiveScaffold.leftInOut,
          // outAnimation: AdaptiveScaffold.leftOutIn,
          builder: (_) => _buildBodyView(),
        ),
      },
    );
  }

  ///SecondaryBody视图
  Widget _buildSecondaryBodyView() {
    var pageView = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      ScrollPhysics? physics = const NeverScrollableScrollPhysics();
      if (!indexWidgetProvider.bottomBarVisible) {
        physics = null;
      }
      return PageView.builder(
        physics: physics,
        controller: indexWidgetProvider.controller,
        onPageChanged: (int index) {
          indexWidgetProvider.currentIndex = index;
        },
        itemCount: indexWidgetProvider.views.length,
        itemBuilder: (BuildContext context, int index) {
          if (index > 3 || appDataProvider.smallBreakpoint.isActive(context)) {
            var view = indexWidgetProvider.views[index];

            return view;
          } else {
            return Container();
          }
        },
      );
    });

    return pageView;
  }

  /// 放置SecondaryBody
  SlotLayout _buildSecondaryBody() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.smallBreakpoint: SlotLayout.from(
          key: const Key('Secondary body'),
          // outAnimation: AdaptiveScaffold.stayOnScreen,
          builder: (_) => _buildSecondaryBodyView(),
        ),
        appDataProvider.mediumBreakpoint: SlotLayout.from(
          key: const Key('Secondary body'),
          // outAnimation: AdaptiveScaffold.stayOnScreen,
          builder: (_) => _buildSecondaryBodyView(),
        ),
        appDataProvider.largeBreakpoint: SlotLayout.from(
          key: const Key('Secondary body'),
          //outAnimation: AdaptiveScaffold.stayOnScreen,
          builder: (_) => _buildSecondaryBodyView(),
        )
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 自动适配的布局，由六个SlotLayout组成，有Top navigation，Body和Bottom navigation三个SlotLayout
    // Body SlotLayout有Primary navigation，Body，Secondary body和Secondary navigation四个SlotLayout
    double? bodyRatio = appDataProvider.smallBreakpoint.isActive(context)
        ? 0.0
        : appDataProvider.bodyRatio;
    return Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return AdaptiveLayout(
          primaryNavigation: primaryNavigation.build(indexWidgetProvider),
          body: _buildBody(),
          secondaryBody: _buildSecondaryBody(),
          bodyRatio: bodyRatio,
          bottomNavigation:
              indexWidgetProvider.bottomBarVisible && !appDataProvider.landscape
                  ? bottomNavigation.build(indexWidgetProvider)
                  : null);
    });
  }

  @override
  void dispose() {
    _chatSlideController.dispose();
    _linkmanSlideController.dispose();
    _channelSlideController.dispose();
    _meSlideController.dispose();
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
