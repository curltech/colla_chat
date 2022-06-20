import 'package:flutter/material.dart';

import 'data_listtile.dart';

class DataListViewController extends ChangeNotifier {
  List<TileData> tileData;
  int currentIndex = 0;

  DataListViewController({this.tileData = const <TileData>[]});

  TileData get current {
    return tileData[currentIndex];
  }

  TileData? getTileData(int index) {
    if (index >= 0) {
      if (index < tileData.length) {
        return tileData[index];
      } else {
        ///这里获取新数据，比如下一页，然后再返回
      }
    }

    return null;
  }

  add(List<TileData> tiles) {
    tileData.addAll(tiles);
    notifyListeners();
  }
}

///根据构造函数传入的数据列表，构造无限滚动的列表视图
class DataListView extends StatefulWidget {
  DataListViewController dataListViewController;

  DataListView(this.dataListViewController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DataListView();
  }
}

class _DataListView extends State<DataListView> {
  @override
  initState() {
    super.initState();

    widget.dataListViewController.addListener(() {
      setState(() {});
    });
  }

  @override
  dispose() {
    super.dispose();
    widget.dataListViewController.dispose();
  }

  Widget _buildGroup(BuildContext context) {
    Widget groupWidget = ListView.builder(
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          TileData? tile = widget.dataListViewController.getTileData(index);
          tile = tile ?? TileData(title: '没有数据了');
          DataListTile tileWidget = DataListTile(tileData: tile);
          return tileWidget;
        });

    return groupWidget;
  }

  @override
  Widget build(BuildContext context) {
    return _buildGroup(context);
  }
}
