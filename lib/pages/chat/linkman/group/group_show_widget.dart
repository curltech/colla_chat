import 'package:colla_chat/pages/chat/linkman/linkman/linkman_info_card.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import '../../../../entity/chat/contact.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';

final List<String> groupFields = [
  'name',
  'peerId',
  'givenName',
  'avatar',
  'mobile',
  'email',
  'sourceType',
  'lastConnectTime',
  'createDate',
  'updateDate'
];

//联系人显示页面
class GroupShowWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Group> controller;

  const GroupShowWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupShowWidgetState();

  @override
  String get routeName => 'group_show';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'GroupShow';
}

class _GroupShowWidgetState extends State<GroupShowWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildGroupInfoCard(BuildContext context) {
    Map<String, dynamic> values = {};
    Map<String, dynamic> groupMap;
    Group? group = widget.controller.current;
    if (group != null) {
      groupMap = group.toJson();
      for (var groupField in groupFields) {
        if (groupMap.containsKey(groupField)) {
          values[groupField] = groupMap[groupField];
        }
      }
    }
    Widget groupInfoCard = LinkmanInfoCard(
      values: values,
    );
    return groupInfoCard;
  }

  @override
  Widget build(BuildContext context) {
    var linkmanInfoCard = _buildGroupInfoCard(context);
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: linkmanInfoCard);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
