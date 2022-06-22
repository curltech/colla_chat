import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/index_widget_provider.dart';
import '../channel/channel_widget.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman_view.dart';
import '../me/me_widget.dart';

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
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.pageController = pageController;
    indexWidgetProvider.define(ChatTarget());
    indexWidgetProvider.define(LinkmanView());
    indexWidgetProvider.define(ChannelWidget());
    indexWidgetProvider.define(MeWidget());
  }

  ///workspace工作区视图
  Widget _createPageView(BuildContext context) {
    var pageView = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return PageView(
        //physics: const NeverScrollableScrollPhysics(),
        controller: indexWidgetProvider.pageController,
        children: indexWidgetProvider.views,
        onPageChanged: (int index) {
          indexWidgetProvider.setCurrentIndex(index, context: context);
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
