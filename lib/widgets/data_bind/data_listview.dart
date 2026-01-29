import 'dart:async';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///根据构造函数传入的数据列表，构造内容与空间匹配的ListView列表视图
///利用DataListViewController修改数据，然后重新执行ListView.build
///外部可能有ListView或者PageView等滚动视图，所以shrinkWrap: true,
class DataListView extends StatelessWidget {
  final bool reverse;
  final int itemCount;
  final double? dividerHeight;
  final Color? dividerColor;
  final ScrollController scrollController = ScrollController();
  final TileData? Function(BuildContext, int)? itemBuilder;
  final Future<TileData?> Function(BuildContext, int)? futureItemBuilder;
  final Future<void> Function()? onScrollMax;
  final Future<void> Function()? onScrollMin;
  final Future<void> Function()? onRefresh;
  final Future<bool?> Function(
    int index,
    String title, {
    String? subtitle,
  })? onTap;

  DataListView(
      {super.key,
      required this.itemCount,
      this.dividerHeight,
      this.dividerColor,
      this.itemBuilder,
      this.futureItemBuilder,
      this.reverse = false,
      this.onScrollMax,
      this.onScrollMin,
      this.onRefresh,
      this.onTap}) {
    scrollController.addListener(_onScroll);
  }

  Future<void> _onScroll() async {
    double offset = scrollController.offset;
    logger.i('scrolled to $offset');

    ///判断是否滚动到最底，需要加载更多数据
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      logger.i('scrolled to max');
      if (onScrollMax != null) {
        await onScrollMax!();
      }
    }
    if (scrollController.position.pixels ==
        scrollController.position.minScrollExtent) {
      logger.i('scrolled to min');
      if (onScrollMin != null) {
        await onScrollMin!();
      }
    }
  }

  ///下拉刷新数据的地方，比如从数据库取更多数据
  Future<void> _onRefresh() async {
    if (onRefresh != null) {
      await onRefresh!();
    }
  }

  Future<bool?> _onTap(int index, String title, {String? subtitle}) async {
    var onTap = this.onTap;
    if (onTap != null) {
      return await onTap(index, title, subtitle: subtitle);
    }
    return null;
  }

  Widget _buildListView(BuildContext context) {
    Widget listViewWidget = ListView.builder(
        //该属性将决定列表的长度是否仅包裹其内容的长度。
        // 当 ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
        shrinkWrap: true,
        reverse: reverse,
        itemCount: itemCount,
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          if (itemBuilder != null) {
            TileData? tileData = itemBuilder!(context, index);
            if (tileData != null) {
              return DataListTile.buildListTile(
                tileData,
                index: index,
                dividerHeight: dividerHeight,
                dividerColor: dividerColor,
                onTap: _onTap,
              );
            }
          }
          if (futureItemBuilder != null) {
            return PlatformFutureBuilder(
                future: futureItemBuilder!(context, index),
                builder: (BuildContext context, TileData? tileData) {
                  return DataListTile.buildListTile(
                    tileData!,
                    index: index,
                    dividerHeight: dividerHeight,
                    dividerColor: dividerColor,
                    onTap: _onTap,
                  );
                });
          }
          return null;
        });

    if (onRefresh == null) {
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
}
