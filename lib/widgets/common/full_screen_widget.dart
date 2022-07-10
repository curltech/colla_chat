import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_bar_view.dart';

class FullScreenWidget extends StatelessWidget with TileDataMixin {
  final Widget child;

  const FullScreenWidget({Key? key, required this.child}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'full_screen';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => '';

  Widget _buildChild(BuildContext context) {
    IndexWidgetProvider indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context);
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            indexWidgetProvider.pop();
          },
          child: Center(
              child: Container(
            color: Colors.black,
            child: child,
          )),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: title, withLeading: withLeading, child: _buildChild(context));
    return appBarView;
  }
}
