import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../channel/channel_widget.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman_view.dart';
import '../me/me_widget.dart';
import 'index_widget_controller.dart';

///主工作区，是PageView
class IndexWidget extends StatefulWidget {
  IndexWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IndexWidgetState();
  }
}

class _IndexWidgetState extends State<IndexWidget>
    with SingleTickerProviderStateMixin {
  var endDrawer = const EndDrawer();

  @override
  void initState() {
    super.initState();
    PageController pageController = PageController();
    var indexWidgetController =
        Provider.of<IndexWidgetController>(context, listen: false);
    indexWidgetController.pageController = pageController;
    indexWidgetController.define(ChatTarget());
    indexWidgetController.define(LinkmanView());
    indexWidgetController.define(ChannelWidget());
    indexWidgetController.define(MeWidget());
  }

  ///workspace工作区视图
  Widget _createPageView(BuildContext context) {
    var pageView = Consumer<IndexWidgetController>(
        builder: (context, indexWidgetController, child) {
      return PageView(
        //physics: const NeverScrollableScrollPhysics(),
        controller: indexWidgetController.pageController,
        children: indexWidgetController.views,
        onPageChanged: (int index) {
          indexWidgetController.currentIndex = index;
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
    // 释放资源
    super.dispose();
    var indexWidgetController = IndexWidgetController.instance;
    indexWidgetController.dispose();
  }
}
