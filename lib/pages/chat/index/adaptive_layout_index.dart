import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/pages/chat/channel/subscribe_channel_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/index/bottom_navigation.dart';
import 'package:colla_chat/pages/chat/index/primary_navigation.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_widget.dart';
import 'package:colla_chat/pages/chat/me/me_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';

///自动适配的主页面结构
class AdaptiveLayoutIndex extends StatefulWidget {
  AdaptiveLayoutIndex({super.key}) {
    indexWidgetProvider.initMainView(SwiperController(), [
      ChatListWidget(),
      LinkmanListWidget(),
      SubscribeChannelListWidget(),
      MailWidget(),
      MeWidget()
    ]);
  }

  @override
  State<AdaptiveLayoutIndex> createState() => _AdaptiveLayoutIndexState();
}

class _AdaptiveLayoutIndexState extends State<AdaptiveLayoutIndex>
    with TickerProviderStateMixin {
  @override
  void initState() {
    appDataProvider.addListener(_update);
    primaryNavigation.initController(this);
    primaryNavigation.forward();
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
    ]);
  }

  /// 放置Body
  SlotLayout? _buildBody() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.mediumBreakpoint: SlotLayout.from(
          key: const Key('Body Medium'),
          builder: (_) => _buildBodyView(),
        ),
        appDataProvider.largeBreakpoint: SlotLayout.from(
          key: const Key('Body Large'),
          builder: (_) => _buildBodyView(),
        ),
      },
    );
  }

  ///SecondaryBody视图
  Widget _buildSecondaryBodyView(BuildContext context) {
    var pageView = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      ScrollPhysics? physics = const NeverScrollableScrollPhysics();
      if (!indexWidgetProvider.bottomBarVisible) {
        physics = null;
      }
      return Swiper(
        physics: physics,
        controller: indexWidgetProvider.controller,
        onIndexChanged: (int index) {
          logger.i('PageChanged:$index');
          //indexWidgetProvider.pop(context: context);
        },
        itemCount: indexWidgetProvider.views.length,
        itemBuilder: (BuildContext context, int index) {
          Widget view;
          if (index >= indexWidgetProvider.mainViews.length ||
              appDataProvider.smallBreakpoint.isActive(context)) {
            view = indexWidgetProvider.views[index];
          } else {
            view = Container();
          }
          return Row(
            children: [
              const VerticalDivider(
                width: 1.0,
              ),
              Expanded(child: view)
            ],
          );
        },
      );
    });

    return pageView;
  }

  /// 放置SecondaryBody
  SlotLayout _buildSecondaryBody(BuildContext context) {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        appDataProvider.smallBreakpoint: SlotLayout.from(
          key: const Key('Secondary body'),
          outAnimation: AdaptiveScaffold.stayOnScreen,
          builder: (_) => _buildSecondaryBodyView(context),
        ),
        appDataProvider.mediumBreakpoint: SlotLayout.from(
          key: const Key('Secondary body'),
          outAnimation: AdaptiveScaffold.stayOnScreen,
          builder: (_) => _buildSecondaryBodyView(context),
        ),
        appDataProvider.largeBreakpoint: SlotLayout.from(
          key: const Key('Secondary body'),
          outAnimation: AdaptiveScaffold.stayOnScreen,
          builder: (_) => _buildSecondaryBodyView(context),
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
          secondaryBody: _buildSecondaryBody(context),
          bodyRatio: bodyRatio,
          bottomNavigation:
              indexWidgetProvider.bottomBarVisible && !appDataProvider.landscape
                  ? bottomNavigation.build(indexWidgetProvider)
                  : null);
    });
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    primaryNavigation.dispose();
    super.dispose();
  }
}
