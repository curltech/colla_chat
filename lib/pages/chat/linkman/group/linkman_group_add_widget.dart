
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///创建和修改群，填写群的基本信息，选择群成员和群主
class LinkmanGroupAddWidget extends StatefulWidget with TileDataMixin {
  LinkmanGroupAddWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.person;

  @override
  String get routeName => 'linkman_add_group';

  @override
  String get title => 'Linkman add group';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupAddWidgetState();
}

class _LinkmanGroupAddWidgetState extends State<LinkmanGroupAddWidget> {
  @override
  initState() {
    super.initState();
    groupController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add group';
    Group? current = groupController.current;
    if (current != null) {
      title = 'Edit group';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: GroupEditWidget(key: UniqueKey(), group: current));

    return appBarView;
  }

  @override
  void dispose() {
    groupController.removeListener(_update);
    super.dispose();
  }
}
