import 'package:flutter/material.dart';

import '../../../widgets/data_tile.dart';
import '../../../widgets/document_tile.dart';

final List<DocumentData> channelTileData = [
  DocumentData(
    icon: const Icon(Icons.collections),
    title: '胡劲松',
  ),
  DocumentData(
    icon: const Icon(Icons.settings),
    title: '胡百水',
  )
];

//频道页面
class Channel extends StatelessWidget {
  final List<DocumentData> documentData = channelTileData;

  Channel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (var tile in documentData) {
      var widget = DocumentTile(documentData: tile);
      children.add(widget);
    }
    return Scaffold(
      //列表
      body: ListView(
        children: children,
      ),
    );
  }
}
