import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../tool/util.dart';
import '../../../widgets/common/data_listview.dart';
import '../../../widgets/common/widget_mixin.dart';

final Map<TileData, List<TileData>> mockTileData = {
  TileData(title: '群'): [
    TileData(title: '家庭群', subtitle: '美国留学', suffix: DateUtil.currentDate()),
    TileData(title: 'MBA群', subtitle: '上海团购', suffix: DateUtil.currentDate()),
  ],
  TileData(title: '个人'): [
    TileData(title: '李志群', subtitle: '', suffix: DateUtil.currentDate()),
    TileData(title: '胡百水', subtitle: '', suffix: DateUtil.currentDate()),
  ]
};

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatTarget extends StatelessWidget with BackButtonMixin, RouteNameMixin {
  /// 聊天目标的数据
  late final Map<TileData, List<TileData>> chatTargets = mockTileData;

  ChatTarget({Key? key}) : super(key: key);

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
    var body = DataListView(tileData: chatTargets);
    return Scaffold(appBar: appBar, body: body);
  }

  @override
  bool get withBack => true;

  @override
  String get routeName => 'chat';
}
