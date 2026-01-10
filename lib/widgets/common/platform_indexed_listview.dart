import 'package:flutter/material.dart';
import 'package:indexed_list_view/indexed_list_view.dart';

class PlatformIndexedListView extends StatelessWidget {
  final IndexedScrollController controller = IndexedScrollController();
  final Widget Function(BuildContext, int) itemBuilder;

  final IndexedWidgetBuilderOrNull emptyItemBuilder;

  final bool separated;

  final Axis scrollDirection;

  final bool reverse;

  final int? maxItemCount;
  final int? minItemCount;
  final bool addAutomaticKeepAlives;

  final bool addRepaintBoundaries;

  final ScrollPhysics? physics;

  final EdgeInsets? padding;

  final double? itemExtent;

  final double? cacheExtent;

  PlatformIndexedListView(
      {super.key,
      required this.itemBuilder,
      this.emptyItemBuilder = IndexedListView.defaultEmptyItemBuilder,
      this.separated = false,
      this.scrollDirection = Axis.vertical,
      this.reverse = false,
      this.maxItemCount,
      this.minItemCount,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.physics,
      this.padding,
      this.itemExtent,
      this.cacheExtent});

  void jumpToIndex(int index) {
    controller.jumpToIndex(index);
  }

  void jumpToIndexAndOffset(int index, double offset) {
    controller.jumpToIndexAndOffset(index: index, offset: offset);
  }

  Future<void> animateToIndex(int index) async {
    await controller.animateToIndex(index);
  }

  Future<void> animateToIndexAndOffset(int index, double offset) async {
    await controller.animateToIndexAndOffset(index: index, offset: offset);
  }

  void jumpTo(double offset) {
    controller.jumpTo(offset);
  }

  Future<void> animateTo(double offset) async {
    await controller.animateTo(offset);
  }

  void jumpToWithSameOriginIndex(double offset) {
    controller.jumpToWithSameOriginIndex(offset);
  }

  Future<void> animateToWithSameOriginIndex(double offset) async {
    await controller.animateToWithSameOriginIndex(offset);
  }

  void jumpToRelative(double offset) {
    controller.jumpToRelative(offset);
  }

  Future<void> animateToRelative(double offset) async {
    await controller.animateToRelative(offset);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedListView.builder(
      controller: controller,
      itemBuilder: itemBuilder,
      emptyItemBuilder: emptyItemBuilder,
      scrollDirection: scrollDirection,
      reverse: reverse,
      physics: physics,
      padding: padding,
      itemExtent: itemExtent,
      maxItemCount: maxItemCount,
      minItemCount: minItemCount,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      cacheExtent: cacheExtent,
    );
  }
}
