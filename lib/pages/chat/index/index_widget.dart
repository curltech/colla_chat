import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/index_widget_provider.dart';
import '../channel/channel_widget.dart';
import '../chat/chat_list_widget.dart';
import '../linkman/linkman_view.dart';
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
    indexWidgetProvider.define(LinkmanView());
    indexWidgetProvider.define(ChannelWidget());
    indexWidgetProvider.define(MeWidget());
  }

  ///workspace工作区视图
  Widget _createPageView(BuildContext context) {
    var pageView = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return PageView.builder(
        //physics: const NeverScrollableScrollPhysics(),
        controller: indexWidgetProvider.pageController,
        onPageChanged: (int index) {
          indexWidgetProvider.setCurrentIndex(index, context: context);
        },
        itemCount: indexWidgetProvider.views.length,
        itemBuilder: (BuildContext context, int index) {
          return indexWidgetProvider.views[index];
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
