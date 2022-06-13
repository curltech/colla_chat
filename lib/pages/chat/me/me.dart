import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../widgets/common/data_listview.dart';

final Map<String, List<TileData>> mockTileData = {
  '未知': [
    TileData(
        icon: const Icon(Icons.collections),
        title: '收藏',
        routeName: '/chat/collection'),
    TileData(
        icon: const Icon(Icons.settings),
        title: '设置',
        routeName: '/chat/setting'),
  ]
};

//我的页面
class Me extends StatelessWidget {
  late final Map<String, List<TileData>> meTileData = mockTileData;

  Me({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      elevation: 0,
      centerTitle: false,
      title: Text(
        AppLocalizations.instance.text('Chat'),
      ),
      actions: [],
    );
    var body = DataListView(tileData: meTileData);
    return Scaffold(
      appBar: appBar,
      //列表
      body: body,
    );
  }
}
