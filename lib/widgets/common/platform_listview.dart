import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class PlatformListView extends StatelessWidget {
  final controller = PagingController<int, Widget>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) {
      return [Container()];
    },
  );

  PlatformListView({super.key});

  Widget _buildPagedListView() {
    return PagingListener(
      controller: controller,
      builder: (context, state, fetchNextPage) => PagedListView<int, Widget>(
        state: state,
        fetchNextPage: fetchNextPage,
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, item, index) {
            return Container();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
