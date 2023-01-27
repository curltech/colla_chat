import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/quill_richtext_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CollectionItemWidget extends StatefulWidget with TileDataMixin {
  CollectionItemWidget({Key? key}) : super(key: key);

  @override
  State createState() => _CollectionItemWidgetState();

  @override
  String get routeName => 'collection_item';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.collections;

  @override
  String get title => 'Collection Item';
}

class _CollectionItemWidgetState extends State<CollectionItemWidget> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      title: widget.title,
      child: const QuillRichTextWidget(),
    );
  }
}
