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
    List<DataTile> tiles = [];
    for (var entry in values.entries) {
      var key = entry.key;
      String value = '';
      if (entry.value != null) {
        value = entry.value!.toString();
      }
      var length = value.length;
      if (length < 30) {
        tiles.add(DataTile(
          title: key,
          suffix: value,
        ));
      } else {
        tiles.add(DataTile(
          title: key,
          subtitle: value,
        ));
      }
    }
    return DataListView(
      itemCount: values.keys.length,
      itemBuilder: (BuildContext context, int index) {
        List<String> keys = values.keys.toList();
        String? key = keys[index];
        String value = values[key] == null ? '' : values[key].toString();
        var length = value.length;
        if (length < 30) {
          return DataTile(
            title: key,
            suffix: value,
          );
        } else {
          return DataTile(
            title: key,
            subtitle: value,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildDataListView(context);
  }
}
