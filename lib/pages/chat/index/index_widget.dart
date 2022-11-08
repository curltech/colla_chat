import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/index_widget_provider.dart';
import '../channel/channel_widget.dart';
import '../chat/chat_list_widget.dart';
import '../linkman/linkman_list_widget.dart';
import '../me/me_widget.dart';

///主工作区，是PageView
class IndexWidget extends StatefulWidget {
  IndexWidget({Key? key}) : super(key: key) {
    PageController pageController = PageController();
    indexWidgetProvider.pageController = pageController;
    indexWidgetProvider.define(ChatListWidget());
    indexWidgetProvider.define(LinkmanListWidget());
    indexWidgetProvider.define(ChannelWidget());
    indexWidgetProvider.define(MeWidget());
  }

  @override
  State<StatefulWidget> createState() {
    return _IndexWidgetState();
  }
}

class _IndexWidgetState extends State<IndexWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    ConnectivityUtil.onConnectivityChanged(_onConnectivityChanged);
  }

  _onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      DialogUtil.error(context, content: 'Connectivity were break down');
    } else {
      DialogUtil.info(context,
          content: 'Connectivity status was changed to:${result.name}');
    }
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
        controller: indexWidgetProvider.pageController,
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

  @override
  void dispose() {
    super.dispose();
  }
}
