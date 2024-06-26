import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///根据构造函数传入的数据列表，构造内容与空间匹配的ListView列表视图
///利用DataListViewController修改数据，然后重新执行ListView.build
///外部可能有ListView或者PageView等滚动视图，所以shrinkWrap: true,
class DataListView extends StatefulWidget {
  final TileData? group;
  final bool reverse;
  late final DataListController<TileData> controller;
  final Future<void> Function()? onScrollMax;
  final Future<void> Function()? onScrollMin;
  final Future<void> Function()? onRefresh;
  final Function(
    int index,
    String title, {
    String? subtitle,
    TileData? group,
  })? onTap;

  DataListView(
      {super.key,
      List<TileData> tileData = const [],
      int? currentIndex,
      DataListController<TileData>? controller,
      this.group,
      this.reverse = false,
      this.onScrollMax,
      this.onScrollMin,
      this.onRefresh,
      this.onTap}) {
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
  final ScrollController scrollController = ScrollController();

  // late final EasyRefreshController easyRefreshController;

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
    myself.addListener(_update);
    scrollController.addListener(_onScroll);

    ///滚到指定的位置
    // widget.scrollController.animateTo(offset,
    //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
  }

  _update() {
    setState(() {});
  }

  Future<void> _onScroll() async {
    double offset = scrollController.offset;
    logger.i('scrolled to $offset');

    ///判断是否滚动到最底，需要加载更多数据
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      logger.i('scrolled to max');
      if (widget.onScrollMax != null) {
        await widget.onScrollMax!();
      }
    }
    if (scrollController.position.pixels ==
        scrollController.position.minScrollExtent) {
      logger.i('scrolled to min');
      if (widget.onScrollMin != null) {
        await widget.onScrollMin!();
      }
    }
  }

  ///下拉刷新数据的地方，比如从数据库取更多数据
  Future<void> _onRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  Future<void> _onLoad() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  _onTap(int index, String title, {String? subtitle}) {
    var onTap = widget.onTap;
    if (onTap != null) {
      onTap(index, title, subtitle: subtitle, group: widget.group);
    }
  }

  Widget _buildListTile(BuildContext context, DataListTile dataListTile) {
    return Column(children: <Widget>[
      dataListTile,
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: Divider(
          height: 1,
          color: Colors.grey.withOpacity(AppOpacity.lgOpacity),
        ),
      ),
    ]);
  }

  Widget _buildListView(BuildContext context) {
    Widget listViewWidget = ListView.builder(
        //该属性将决定列表的长度是否仅包裹其内容的长度。
        // 当 ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
        shrinkWrap: true,
        reverse: widget.reverse,
        itemCount: widget.controller.length,
        //physics: const NeverScrollableScrollPhysics(),
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          TileData tile = widget.controller.get(index);

          Widget tileWidget = _buildListTile(
              context,
              DataListTile(
                dataListViewController: widget.controller,
                tileData: tile,
                index: index,
                onTap: _onTap,
              ));

          return tileWidget;
        });

    if (widget.onRefresh == null) {
      return listViewWidget;
    }

    Widget view =
        RefreshIndicator(onRefresh: _onRefresh, child: listViewWidget);

    return view;
  }

  @override
  Widget build(BuildContext context) {
    return _buildListView(context);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    scrollController.removeListener(_onScroll);
    myself.removeListener(_update);
    super.dispose();
  }
}
