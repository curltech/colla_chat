import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import '../login/loading.dart';
import 'bottom_bar.dart';
import 'index_widget.dart';
import 'left_bar.dart';

class IndexView extends StatefulWidget {
  final String title;

  const IndexView({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return IndexViewState();
  }
}

class IndexViewState extends State<IndexView>
    with SingleTickerProviderStateMixin {
  var endDrawer = const EndDrawer();

  @override
  void initState() {
    super.initState();
  }

  Widget _createScaffold(
      BuildContext context, IndexWidgetProvider indexWidgetProvider) {
    var indexWidget = const IndexWidget();
    //左边栏，和底部按钮功能一样，在桌面版才有
    var leftToolBar = const LeftBar();
    var bottomNavigationBar = Offstage(
        offstage: !indexWidgetProvider.bottomBarVisible, child: BottomBar());
    Scaffold scaffold;
    //移动手机不需要左边栏，需要底部栏
    if (appDataProvider.mobile) {
      scaffold = Scaffold(
          body: SafeArea(child: Center(child: indexWidget)),
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar);
    } else {
      //桌面版不需要底部栏，需要固定的左边栏
      scaffold = Scaffold(
        body: SafeArea(
            child: Stack(children: <Widget>[
          Opacity(
            opacity: 1,
            child: Loading(title: ''),
          ),
          Center(
              child: Row(
            children: <Widget>[
              leftToolBar,
              const VerticalDivider(thickness: 0.5),
              Expanded(child: indexWidget),
            ],
          )),
        ])),
      );
    }

    return scaffold;
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var provider = Consumer<IndexWidgetProvider>(
      builder: (context, indexWidgetProvider, child) =>
          _createScaffold(context, indexWidgetProvider),
    );
    return provider;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
