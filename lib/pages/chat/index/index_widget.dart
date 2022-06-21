import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:flutter/material.dart';

import '../channel/channel_widget.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman_view.dart';
import '../me/me_widget.dart';
import 'index_widget_controller.dart';

///主工作区，是PageView
class IndexWidget extends StatefulWidget {
  ///对应的控制器，控制PageView的流转
  IndexWidgetController indexWidgetController = IndexWidgetController.instance;
  IndexWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return IndexWidgetState();
  }
}

class IndexWidgetState extends State<IndexWidget>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  var endDrawer = const EndDrawer();
  late Map<String, String> _widgetLabels;

  @override
  void initState() {
    super.initState();
    widget.indexWidgetController.addListener(() {
      setState(() {});
    });
    PageController pageController = PageController();
    widget.indexWidgetController.pageController = pageController;
    widget.indexWidgetController.define(ChatTarget());
    widget.indexWidgetController.define(LinkmanView());
    widget.indexWidgetController.define(ChannelWidget());
    widget.indexWidgetController.define(MeWidget());
  }

  ///workspace工作区视图
  Widget _createPageView(BuildContext context) {
    var indexWidgetController = widget.indexWidgetController;
    var pageView = PageView(
      //physics: const NeverScrollableScrollPhysics(),
      controller: indexWidgetController.pageController,
      children: indexWidgetController.views,
      onPageChanged: (int index) {
        indexWidgetController.currentIndex = index;
      },
    );

    return pageView;
  }

  @override
  Widget build(BuildContext context) {
    var pageView = _createPageView(context);
    return pageView;
  }

  @override
  void dispose() {
    // 释放资源
    super.dispose();
    var indexViewProvider = IndexWidgetController.instance;
    indexViewProvider.dispose();
  }
}
