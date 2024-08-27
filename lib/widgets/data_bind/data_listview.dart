import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///根据构造函数传入的数据列表，构造内容与空间匹配的ListView列表视图
///利用DataListViewController修改数据，然后重新执行ListView.build
///外部可能有ListView或者PageView等滚动视图，所以shrinkWrap: true,
class DataListView extends StatefulWidget {
  final TileData? group;
  final bool reverse;
  final int itemCount;
  final TileData? Function(BuildContext, int)? itemBuilder;
  final Future<TileData?> Function(BuildContext, int)? futureItemBuilder;
  final Future<void> Function()? onScrollMax;
  final Future<void> Function()? onScrollMin;
  final Future<void> Function()? onRefresh;
  final Function(
    int index,
    String title, {
    String? subtitle,
    TileData? group,
  })? onTap;

  const DataListView(
      {super.key,
      required this.itemCount,
      this.itemBuilder,
      this.futureItemBuilder,
      this.group,
      this.reverse = false,
      this.onScrollMax,
      this.onScrollMin,
      this.onRefresh,
      this.onTap});

  @override
  State<StatefulWidget> createState() {
    return _DataListViewState();
  }
}

class _DataListViewState extends State<DataListView> {
  final ScrollController scrollController = ScrollController();

  @override
  initState() {
    super.initState();
    scrollController.addListener(_onScroll);

    ///滚到指定的位置
    // widget.scrollController.animateTo(offset,
    //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
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
        itemCount: widget.itemCount,
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          if (widget.itemBuilder != null) {
            TileData? tileData = widget.itemBuilder!(context, index);
            if (tileData != null) {
              return _buildListTile(
                  context,
                  DataListTile(
                    tileData: tileData,
                    index: index,
                    onTap: _onTap,
                  ));
            }
          }
          if (widget.futureItemBuilder != null) {
            return PlatformFutureBuilder(
                future: widget.futureItemBuilder!(context, index),
                builder: (BuildContext context, TileData? tileData) {
                  return _buildListTile(
                      context,
                      DataListTile(
                        tileData: tileData!,
                        index: index,
                        onTap: _onTap,
                      ));
                });
          }
          return null;
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
    scrollController.removeListener(_onScroll);
    super.dispose();
  }
}
