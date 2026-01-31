import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//我的页面，带有路由回调函数
class WebSocketWidget extends StatelessWidget with DataTileMixin {
  WebSocketWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'web_socket';

  @override
  IconData get iconData => Icons.webhook_outlined;

  @override
  String get title => 'WebSocket';

  

  List<DataTile> _buildMeTileData(BuildContext context) {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<DataTile> meTileData = _buildMeTileData(context);
    Widget child = DataListView(
      itemCount: meTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return meTileData[index];
      },
    );

    var me = AppBarView(title: title, helpPath: routeName,child: child);
    return me;
  }
}
