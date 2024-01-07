import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///多个字段显示
class ValueListView extends StatelessWidget {
  final Map<String, dynamic> values;

  const ValueListView({
    super.key,
    required this.values,
  });

  Widget _buildDataListView(BuildContext context) {
    List<TileData> tiles = [];
    for (var entry in values.entries) {
      var key = entry.key;
      String value = '';
      if (entry.value != null) {
        value = entry.value!.toString();
      }
      var length = value.length;
      if (length < 30) {
        tiles.add(TileData(
          title: key,
          suffix: value,
        ));
      } else {
        tiles.add(TileData(
          title: key,
          subtitle: value,
        ));
      }
    }
    return DataListView(tileData: tiles);
  }

  @override
  Widget build(BuildContext context) {
    return _buildDataListView(context);
  }
}
