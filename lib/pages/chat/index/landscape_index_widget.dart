import 'package:colla_chat/pages/chat/channel/subscribe_channel_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/index/left_bar.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/me/me_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///横屏的主工作区，最左边是主菜单项，右边分为两屏，第一屏为主菜单屏，
///最右边为最新界面屏，是PageView，可以最大化
class LandscapeIndexWidget extends StatefulWidget {
  LandscapeIndexWidget({Key? key}) : super(key: key) {
    PageController controller = PageController();
    indexWidgetProvider.controller = controller;
    indexWidgetProvider.define(ChatListWidget());
    indexWidgetProvider.define(LinkmanListWidget());
    indexWidgetProvider.define(SubscribeChannelListWidget());
    indexWidgetProvider.define(MeWidget());
  }

  @override
  State<StatefulWidget> createState() {
    return _LandscapeIndexWidgetState();
  }
}

class _LandscapeIndexWidgetState extends State<LandscapeIndexWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  ///主菜单视图
  Widget _createMainView(BuildContext context) {
    var mainView = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      double width = appDataProvider.actualMainViewWidth;
      return SizedBox(
          width: width,
          child:
              indexWidgetProvider.views[indexWidgetProvider.currentMainIndex]);
    });

    return mainView;
  }

  ///workspace工作区视图
  Widget _createPageView(BuildContext context) {
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
          if (index > 3) {
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

  @override
  Widget build(BuildContext context) {
    var pageView = Row(children: [
      const LeftBar(),
      _createMainView(context),
      VerticalDivider(width: appDataProvider.dividerWidth),
      Expanded(child: _createPageView(context)),
    ]);

    return pageView;
  }
}
