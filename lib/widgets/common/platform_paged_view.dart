import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

enum ViewType {
  list,
  page,
  grid,
}

enum GridType {
  square,
  masonry,
  aligned,
}

/// 分页视图，包括list，grid
/// PageKeyType：页号类型，ItemType：元素类型
class PlatformPagedView<ItemType> extends StatelessWidget {
  final FutureOr<List<ItemType>> Function(int) fetchPage;
  final Widget Function(BuildContext, ItemType, int) itemBuilder;
  final ViewType viewType;
  final GridType gridType;
  late final controller = PagingController<int, ItemType>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: fetchPage,
  );

  final double maxCrossAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  PlatformPagedView(
      {super.key,
      required this.fetchPage,
      required this.itemBuilder,
      this.viewType = ViewType.list,
      this.gridType = GridType.square,
      this.maxCrossAxisExtent = 200,
      this.crossAxisSpacing = 10,
      this.mainAxisSpacing = 10,
      this.childAspectRatio = 1.0}) {
    controller.addListener(_showError);
  }

  Future<void> _showError() async {
    if (controller.value.status == PagingStatus.subsequentPageError) {
      DialogUtil.showSnackBar(
        content: Text(
          AppLocalizations.t('Something went wrong while fetching a new page.'),
        ),
        action: SnackBarAction(
          label: AppLocalizations.t('Retry'),
          onPressed: () => controller.fetchNextPage(),
        ),
      );
    }
  }

  Widget _buildPagedListView() {
    return RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        child: PagingListener(
          controller: controller,
          builder: (context, state, fetchNextPage) =>
              PagedListView<int, ItemType>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: itemBuilder,
            ),
          ),
        ));
  }

  Widget _buildPagedPageView() {
    return RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        child: PagingListener(
          controller: controller,
          builder: (context, state, fetchNextPage) =>
              PagedPageView<int, ItemType>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: itemBuilder,
            ),
          ),
        ));
  }

  Widget _buildPagedSliverGrid() {
    return RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        child: PagingListener(
            controller: controller,
            builder: (context, state, fetchNextPage) =>
                PagedSliverGrid<int, ItemType>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    maxCrossAxisExtent: maxCrossAxisExtent,
                  ),
                  builderDelegate: PagedChildBuilderDelegate(
                    itemBuilder: itemBuilder,
                  ),
                )));
  }

  Widget _buildPagedSliverMasonryGrid() {
    return RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        child: PagingListener(
            controller: controller,
            builder: (context, state, fetchNextPage) =>
                PagedSliverMasonryGrid<int, ItemType>.extent(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  maxCrossAxisExtent: maxCrossAxisExtent,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  builderDelegate: PagedChildBuilderDelegate(
                    itemBuilder: itemBuilder,
                  ),
                )));
  }

  Widget _buildPagedSliverAlignedGrid() {
    return RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        child: PagingListener(
            controller: controller,
            builder: (context, state, fetchNextPage) =>
                PagedSliverAlignedGrid<int, ItemType>.extent(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  maxCrossAxisExtent: maxCrossAxisExtent,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  builderDelegate: PagedChildBuilderDelegate(
                    itemBuilder: itemBuilder,
                  ),
                  showNewPageErrorIndicatorAsGridChild: false,
                  showNewPageProgressIndicatorAsGridChild: false,
                  showNoMoreItemsIndicatorAsGridChild: false,
                )));
  }

  Widget _buildPagedGridView() {
    switch (gridType) {
      case GridType.square:
        return _buildPagedSliverGrid();
      case GridType.masonry:
        return _buildPagedSliverMasonryGrid();
      case GridType.aligned:
        return _buildPagedSliverAlignedGrid();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (viewType) {
      case ViewType.list:
        return _buildPagedListView();
      case ViewType.page:
        return _buildPagedPageView();
      case ViewType.grid:
        return _buildPagedGridView();
    }
  }
}
