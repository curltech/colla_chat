import 'package:flutter/material.dart';

class TileData {
  //图标
  late final Icon icon;

  //标题
  late final String title;
  late final String? subtitle;
  late final String? suffix;
  late final String? routeName;

  TileData(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.suffix,
      this.routeName});
}

//通用列表项
class DataTile extends StatelessWidget {
  //图标
  late final TileData _tileData;

  DataTile({Key? key, required TileData tileData}) : super(key: key) {
    _tileData = tileData;
  }

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    if (_tileData.routeName != null) {
      trailing = Icon(Icons.arrow_forward);
    } else if (_tileData.suffix != null) {
      trailing = Text(
        _tileData.suffix!,
        style: TextStyle(fontSize: 16.0, color: Colors.cyan),
      );
    }
    return ListTile(
      leading: _tileData.icon,
      title: Text(
        _tileData.title,
        style: TextStyle(fontSize: 16.0, color: Colors.cyan),
      ),
      subtitle: _tileData.subtitle != null
          ? Text(
              _tileData.subtitle!,
              style: TextStyle(fontSize: 16.0, color: Colors.cyan),
            )
          : null,
      trailing: trailing,
      onTap: () {
        if (_tileData.routeName != null) {
          Navigator.pushNamed(context, _tileData.routeName!);
        }
      },
    );
  }
}
