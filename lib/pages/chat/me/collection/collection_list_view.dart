import 'package:colla_chat/pages/chat/me/collection/collection_item_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

//收藏的页面
class CollectionListView extends StatelessWidget with TileDataMixin {
  final Future<void> Function()? onRefresh;
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final ScrollController scrollController = ScrollController();
  final CollectionItemWidget collectionItemWidget = CollectionItemWidget();

  CollectionListView(
      {super.key, this.onRefresh, this.onScrollMax, this.onScrollMin}) {
    indexWidgetProvider.define(collectionItemWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'collection';

  @override
  IconData get iconData => Icons.collections;

  @override
  String get title => 'Collection';

  @override
  String? get information => null;

  @override
  Widget build(BuildContext context) {
    final CollectionListWidget collectionListWidget = CollectionListWidget();
    var appBarView = AppBarView(
      title: title,
      withLeading: withLeading,
      child: collectionListWidget,
    );

    return appBarView;
  }
}
