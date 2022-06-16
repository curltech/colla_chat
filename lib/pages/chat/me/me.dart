import 'package:flutter/material.dart';

import '../../../provider/app_data.dart';
import '../../../widgets/common/data_listview.dart';
import '../chat/widget/app_bar_view.dart';

final Map<String, List<TileData>> mockTileData = {
  'Me': [
    TileData(
        icon: Icon(Icons.collections,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: '收藏'),
    TileData(
        icon: Icon(Icons.settings,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: '设置'),
  ]
};

//我的页面
class MeWidget extends StatelessWidget {
  late final Map<String, List<TileData>> meTileData = mockTileData;

  MeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var me = AppBarView(title: 'Me', child: DataListView(tileData: meTileData));
    return me;
  }
}
