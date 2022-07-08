import 'package:flutter/material.dart';

import '../../provider/app_data_provider.dart';
import '../../provider/data_list_controller.dart';
import 'data_listtile.dart';

///根据构造函数传入的数据列表，构造内容与空间匹配的ListView列表视图
///利用DataListViewController修改数据，然后重新执行ListView.build
///外部可能有ListView或者PageView等滚动视图，所以shrinkWrap: true,
class DataListView extends StatefulWidget {
  final TileData? group;
  late final DataListController<TileData> controller;
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
      List<TileData> tileData = const [],
      int? currentIndex,
      DataListController<TileData>? controller,
      this.group,
      this.onScrollMax,
      this.onRefresh,
      this.onTap})
      : super(key: key) {
    if (controller != null) {
      this.controller = controller;
    } else {
      this.controller = DataListController<TileData>(
          data: tileData, currentIndex: currentIndex);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _DataListViewState();
  }
}

class _DataListViewState extends State<DataListView> {
  @override
  initState() {
    widget.controller.addListener(_update);
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

  _update() {
    setState(() {});
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
            itemCount: widget.controller.length,
            //physics: const NeverScrollableScrollPhysics(),
            controller: widget.scrollController,
            itemBuilder: (BuildContext context, int index) {
              TileData tile = widget.controller.get(index);

              DataListTile tileWidget = DataListTile(
                dataListViewController: widget.controller,
                tileData: tile,
                index: index,
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
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
