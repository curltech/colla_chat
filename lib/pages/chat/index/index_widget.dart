import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import '../../../provider/index_widget_provider.dart';
import '../channel/channel_widget.dart';
import '../chat/chat_list_widget.dart';
import '../linkman/linkman_list_widget.dart';
import '../me/me_widget.dart';

///主工作区，是PageView
class IndexWidget extends StatefulWidget {
  const IndexWidget({Key? key}) : super(key: key);

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
    PageController pageController = PageController();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.pageController = pageController;
    indexWidgetProvider.define(ChatListWidget());
    indexWidgetProvider.define(LinkmanListWidget());
    indexWidgetProvider.define(ChannelWidget());
    indexWidgetProvider.define(MeWidget());
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
          var currentIndex = indexWidgetProvider.currentIndex;
          //目标是主视图，或者回退到先前的视图都从堆栈弹出
          if (index < 4 || currentIndex > index) {
            if (!indexWidgetProvider.popAction) {
              indexWidgetProvider.pop(context: context);
            }
            indexWidgetProvider.popAction = false;
          }
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
