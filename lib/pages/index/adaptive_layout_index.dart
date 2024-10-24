import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/pages/chat/channel/subscribe_channel_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/game/game_main_widget.dart';
import 'package:colla_chat/pages/index/bottom_navigation.dart';
import 'package:colla_chat/pages/index/other_app_widget.dart';
import 'package:colla_chat/pages/index/primary_navigation.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/chat/me/me_widget.dart';
import 'package:colla_chat/pages/stock/stock_main_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';

///自动适配的主页面结构
class AdaptiveLayoutIndex extends StatefulWidget {
  final PrimaryNavigation primaryNavigation = PrimaryNavigation();
  final BottomNavigation bottomNavigation = BottomNavigation();

  AdaptiveLayoutIndex({super.key}) {
    List<TileDataMixin> views = [
      ChatListWidget(),
      LinkmanListWidget(),
      SubscribeChannelListWidget(),
      MeWidget(),
      OtherAppWidget(),
    ];
    indexWidgetProvider.initMainView(SwiperController(), views);
  }

  @override
  State<AdaptiveLayoutIndex> createState() => _AdaptiveLayoutIndexState();
}

class _AdaptiveLayoutIndexState extends State<AdaptiveLayoutIndex>
    with TickerProviderStateMixin {
  @override
  void initState() {
    widget.primaryNavigation.initController(this);
    widget.primaryNavigation.forward();
    super.initState();
  }

  ///Body视图
  Widget _buildBodyView() {
    TileDataMixin mixin =
        indexWidgetProvider.views[indexWidgetProvider.currentMainIndex];
    return Row(children: [
      const VerticalDivider(
        width: 1.0,
      ),
      Expanded(child: mixin),
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
    ScrollPhysics? physics = const NeverScrollableScrollPhysics();
    // if (!indexWidgetProvider.bottomBarVisible) {
    //   physics = null;
    // }
    var pageView = Swiper(
      physics: physics,
      controller: indexWidgetProvider.controller,
      onIndexChanged: (int index) {
        //logger.i('PageChanged:$index');
        //indexWidgetProvider.pop(context: context);
      },
      itemCount: indexWidgetProvider.views.length,
      itemBuilder: (BuildContext context, int index) {
        if (appDataProvider.smallBreakpoint.isActive(context)) {
          return indexWidgetProvider.views[index];
        }
        Widget view;
        if (index >= indexWidgetProvider.mainViews.length) {
          view = indexWidgetProvider.views[index];
        } else {
          view = nilBox;
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
    return Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(builder:
        (context, appDataProvider, indexWidgetProvider, myself, child) {
      // 自动适配的布局，由六个SlotLayout组成，有Top navigation，Body和Bottom navigation三个SlotLayout
      // Body SlotLayout有Primary navigation，Body，Secondary body和Secondary navigation四个SlotLayout
      double? bodyRatio = appDataProvider.smallBreakpoint.isActive(context)
          ? 0.0
          : appDataProvider.bodyRatio;

      SlotLayout? bottomSlotLayout;
      if (indexWidgetProvider.bottomBarVisible && !appDataProvider.landscape) {
        bottomSlotLayout = widget.bottomNavigation.build();
      }
      return AdaptiveLayout(
          primaryNavigation: widget.primaryNavigation.build(),
          body: _buildBody(),
          secondaryBody: _buildSecondaryBody(context),
          bodyRatio: bodyRatio,
          bottomNavigation: bottomSlotLayout);
    });
  }

  @override
  void dispose() {
    widget.primaryNavigation.dispose();
    super.dispose();
  }
}
