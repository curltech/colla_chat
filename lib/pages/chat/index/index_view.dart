import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import '../../../widgets/style/platform_widget_factory.dart';
import '../login/loading.dart';
import 'bottom_bar.dart';
import 'index_widget.dart';

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
    var bottomNavigationBar = Offstage(
        offstage: !indexWidgetProvider.bottomBarVisible,
        child: const BottomBar());
    Scaffold scaffold = Scaffold(
        appBar: AppBar(toolbarHeight: 0.0, elevation: 0.0),
        body: SafeArea(
            child: Stack(children: <Widget>[
          Opacity(
            opacity: 1,
            child: Loading(title: ''),
          ),
          platformWidgetFactory.buildContainer(
              child: Center(child: indexWidget))
        ])),
        //endDrawer: endDrawer,
        bottomNavigationBar: bottomNavigationBar);

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
