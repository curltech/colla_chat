import 'package:flutter/material.dart';

import '../../provider/app_data_provider.dart';
import 'data_listtile.dart';

class DataListViewController extends ChangeNotifier {
  List<TileData> tileData;
  int currentIndex = 0;

  DataListViewController(
      {this.tileData = const <TileData>[],
      Future<List<TileData>> Function(int limit)? more});

  TileData get current {
    return tileData[currentIndex];
  }

  TileData getTileData(int index) {
    return tileData[index];
  }

  add(List<TileData> tiles) {
    tileData.addAll(tiles);
    notifyListeners();
  }
}

///根据构造函数传入的数据列表，构造内容与空间匹配的ListView列表视图
///利用DataListViewController修改数据，然后重新执行ListView.build
///外部可能有ListView或者PageView等滚动视图，所以shrinkWrap: true,
class DataListView extends StatefulWidget {
  DataListViewController dataListViewController;
  final ScrollController scrollController = ScrollController();

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

    widget.scrollController.addListener(() {
      double offset = widget.scrollController.offset;
      logger.i('scrolled to $offset');

      ///判断是否滚动到最底，需要加载更多数据
      if (widget.scrollController.position.pixels ==
          widget.scrollController.position.maxScrollExtent) {
        logger.i('scrolled to max');
      }
      if (widget.scrollController.position.pixels ==
          widget.scrollController.position.minScrollExtent) {
        logger.i('scrolled to min');
      }

      ///滚到指定的位置
      // widget.scrollController.animateTo(offset,
      //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
    });
  }

  @override
  dispose() {
    super.dispose();
    widget.dataListViewController.dispose();
    widget.scrollController.dispose();
  }

  bool _onNotification(ScrollNotification notification) {
    String type = notification.runtimeType.toString();
    logger.i('scrolled to $type');
    return true;
  }

  Future<void> _onRefresh() async {
    ///下拉刷新数据的地方，比如从数据库取更多数据
  }

  Widget _buildGroup(BuildContext context) {
    Widget groupWidget = RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.dataListViewController.tileData.length,
            //physics: const NeverScrollableScrollPhysics(),
            controller: widget.scrollController,
            itemBuilder: (BuildContext context, int index) {
              TileData tile = widget.dataListViewController.getTileData(index);
              DataListTile tileWidget = DataListTile(tileData: tile);

              return tileWidget;
            }));

    return groupWidget;
  }

  @override
  Widget build(BuildContext context) {
    return _buildGroup(context);
  }
}
