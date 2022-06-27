import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../tool/util.dart';
import '../../../widgets/common/data_group_listview.dart';
import '../../../widgets/common/data_listtile.dart';
import '../../../widgets/common/widget_mixin.dart';

final Map<TileData, List<TileData>> mockTileData = {
  TileData(title: '群'): [
    TileData(
        title: '家庭群',
        subtitle: '美国留学',
        suffix: DateUtil.formatChinese(DateUtil.currentDate())),
    TileData(
        title: 'MBA群',
        subtitle: '上海团购',
        suffix: DateUtil.formatChinese('2022-06-20T09:23:45.000Z')),
  ],
  TileData(title: '个人'): [
    TileData(
        title: '李志群',
        subtitle: '',
        suffix: DateUtil.formatChinese('2022-06-21T16:23:45.000Z')),
    TileData(
        title: '胡百水',
        subtitle: '',
        suffix: DateUtil.formatChinese('2022-06-20T21:23:45.000Z')),
  ]
};

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatTarget extends StatelessWidget with TileDataMixin {
  /// 聊天目标的数据
  late final Map<TileData, List<TileData>> chatTargets = mockTileData;
  late final Widget child;

  ChatTarget({Key? key}) : super(key: key) {
    child = GroupDataListView(tileData: chatTargets);
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      title: Text(
        AppLocalizations.instance.text(title),
      ),
      actions: const [],
    );
    return Scaffold(appBar: appBar, body: child);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => 'Chat';
}
