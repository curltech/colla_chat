import 'package:flutter/material.dart';

import '../../provider/app_data_provider.dart';
import 'data_listtile.dart';

///TileData转换器接口定义，根据序列号获取TileData
mixin TileDataConvertMixin {
  TileData getTileData(int index);

  bool add(List<TileData> tiles);

  int get length;
}

///TileData数组的转换器实现类
class ListTileDataConvertMixin with TileDataConvertMixin {
  List<TileData> tileData;

  ListTileDataConvertMixin({required this.tileData});

  @override
  TileData getTileData(int index) {
    return tileData[index];
  }

  @override
  bool add(List<TileData> tiles) {
    if (tiles.isNotEmpty) {
      tileData.addAll(tiles);
      return true;
    }
    return false;
  }

  @override
  int get length => tileData.length;
}

class DataListViewController extends ChangeNotifier {
  TileDataConvertMixin tileDataMix;
  int _currentIndex = 0;

  DataListViewController({required this.tileDataMix});

  TileData get current {
    return tileDataMix.getTileData(_currentIndex);
  }

  TileData getTileData(int index) {
    return tileDataMix.getTileData(index);
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  add(List<TileData> tiles) {
    bool success = tileDataMix.add(tiles);
    if (success) {
      notifyListeners();
    }
  }

  int get length => tileDataMix.length;
}

///根据构造函数传入的数据列表，构造内容与空间匹配的ListView列表视图
///利用DataListViewController修改数据，然后重新执行ListView.build
///外部可能有ListView或者PageView等滚动视图，所以shrinkWrap: true,
class DataListView extends StatefulWidget {
  final TileData? group;
  final List<TileData>? tileData;
  TileDataConvertMixin? tileDataMix;
  late final DataListViewController dataListViewController;
  final ScrollController scrollController = ScrollController();
  final Function()? onScrollMax;
  final Future<void> Function()? onRefresh;
  final Function(
    int index,
    String title, {
    TileData? group,
  })? onTap;

  DataListView(
      {Key? key,
      this.group,
      this.tileData,
      this.tileDataMix,
      this.onScrollMax,
      this.onRefresh,
      this.onTap})
      : super(key: key) {
    if (tileDataMix == null && tileData != null) {
      tileDataMix = ListTileDataConvertMixin(tileData: tileData!);
    }
    dataListViewController = DataListViewController(tileDataMix: tileDataMix!);
    logger.w(
        'key: $key,new dataListViewController: ${dataListViewController.length}:${dataListViewController.currentIndex}');
  }

  @override
  State<StatefulWidget> createState() {
    return _DataListView();
  }
}

class _DataListView extends State<DataListView> {
  @override
  initState() {
    widget.dataListViewController.addListener(update);
    var scrollController = widget.scrollController;
    scrollController.addListener(() {
      double offset = widget.scrollController.offset;
      logger.i('scrolled to $offset');

      ///判断是否滚动到最底，需要加载更多数据
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        logger.i('scrolled to max');
        if (widget.onScrollMax != null) {
          widget.onScrollMax!();
        }
      }
      if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {
        logger.i('scrolled to min');
      }

      ///滚到指定的位置
      // widget.scrollController.animateTo(offset,
      //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
    });

    super.initState();
  }

  void update() {
    //如果数据发生变化（model类调用了notifyListeners），重新构建InheritedProvider
    setState(() => {});
  }

  @override
  void didUpdateWidget(DataListView oldWidget) {
    //当Provider更新时，如果新旧数据不"=="，则解绑旧数据监听，同时添加新数据监听
    if (widget.dataListViewController != oldWidget.dataListViewController) {
      oldWidget.dataListViewController.removeListener(update);
      widget.dataListViewController.addListener(update);
    }
    super.didUpdateWidget(oldWidget);
  }

  bool _onNotification(ScrollNotification notification) {
    String type = notification.runtimeType.toString();
    logger.i('scrolled to $type');
    return true;
  }

  Future<void> _onRefresh() async {
    ///下拉刷新数据的地方，比如从数据库取更多数据
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  _onTap(int index, String title) {
    logger.w(
        'index: $index, title: $title,onTap dataListViewController:${widget.dataListViewController.length}:${widget.dataListViewController.currentIndex}');
    widget.dataListViewController.currentIndex = index;
    var onTap = widget.onTap;
    if (onTap != null) {
      onTap(index, title, group: widget.group);
    }
  }

  Widget _buildGroup(BuildContext context) {
    Widget groupWidget = RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
            //该属性将决定列表的长度是否仅包裹其内容的长度。
            // 当 ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
            shrinkWrap: true,
            itemCount: widget.dataListViewController.length,
            //physics: const NeverScrollableScrollPhysics(),
            controller: widget.scrollController,
            itemBuilder: (BuildContext context, int index) {
              TileData tile = widget.dataListViewController.getTileData(index);

              ///如果当前选择的项目的标题相符，则选择标志为true
              bool selected = false;
              if (widget.dataListViewController.currentIndex == index) {
                selected = true;
              }
              DataListTile tileWidget = DataListTile(
                tileData: tile,
                index: index,
                selected: selected,
                onTap: _onTap,
              );

              return tileWidget;
            }));

    return groupWidget;
  }

  @override
  Widget build(BuildContext context) {
    return _buildGroup(context);
  }

  @override
  void dispose() {
    logger.w(
        'key: ${widget.key}, dispose DataListView:${widget.dataListViewController.length}:${widget.dataListViewController.currentIndex}');
    // widget.scrollController.dispose();
    // widget.dataListViewController.removeListener(update);
    // widget.dataListViewController.dispose();
    super.dispose();
  }
}
