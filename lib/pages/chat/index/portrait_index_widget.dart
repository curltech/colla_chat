import 'package:colla_chat/pages/chat/channel/subscribe_channel_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/me/me_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///竖屏主工作区，是PageView
class PortraitIndexWidget extends StatefulWidget {
  PortraitIndexWidget({Key? key}) : super(key: key) {
    PageController controller = PageController();
    indexWidgetProvider.controller = controller;
    indexWidgetProvider.define(ChatListWidget());
    indexWidgetProvider.define(LinkmanListWidget());
    indexWidgetProvider.define(SubscribeChannelListWidget());
    indexWidgetProvider.define(MeWidget());
  }

  @override
  State<StatefulWidget> createState() {
    return _PortraitIndexWidgetState();
  }
}

class _PortraitIndexWidgetState extends State<PortraitIndexWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
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
          var view = indexWidgetProvider.views[index];
          return view;
        },
      );
    });

    return pageView;
  }

  @override
  Widget build(BuildContext context) {
    var pageView = _createPageView(context);
    return pageView;
  }
}
