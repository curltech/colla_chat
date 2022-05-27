import 'package:flutter/material.dart';

import '../../../widgets/data_listview.dart';

final Map<String, List<TileData>> mockTileData = {
  '群': [
    TileData(
        title: '家庭群',
        subtitle: '美国留学',
        suffix: DateTime.now().toIso8601String()),
    TileData(
        title: 'MBA群',
        subtitle: '上海团购',
        suffix: DateTime.now().toIso8601String()),
  ],
  '个人': [
    TileData(
        title: '李志群', subtitle: '', suffix: DateTime.now().toIso8601String()),
    TileData(
        title: '胡百水', subtitle: '', suffix: DateTime.now().toIso8601String()),
  ]
};

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatTarget extends StatelessWidget {
  /// 聊天目标的数据
  late final Map<String, List<TileData>> chatTargets = mockTileData;

  ChatTarget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body = DataListView(tileData: chatTargets);
    return Scaffold(body: body);
  }
}
