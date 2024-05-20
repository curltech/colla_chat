import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class PoemWidget extends StatefulWidget with TileDataMixin {
  const PoemWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PoemWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'poem';

  @override
  IconData get iconData => Icons.library_music_outlined;

  @override
  String get title => 'Poem';
}

class _PoemWidgetState extends State<PoemWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var personalInfo = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      child: Container(),
    );

    return personalInfo;
  }
}
