import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import '../../../../entity/chat/contact.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';
import 'linkman_info_card.dart';

final List<String> linkmanFields = [
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
class LinkmanShowWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> controller;

  const LinkmanShowWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanShowWidgetState();

  @override
  String get routeName => 'linkman_show';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'LinkmanShow';
}

class _LinkmanShowWidgetState extends State<LinkmanShowWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildLinkmanInfoCard(BuildContext context) {
    Map<String, dynamic> values = {};
    Map<String, dynamic> linkmanMap;
    Linkman? linkman = widget.controller.current;
    if (linkman != null) {
      linkmanMap = linkman.toJson();
      for (var linkmanField in linkmanFields) {
        if (linkmanMap.containsKey(linkmanField)) {
          values[linkmanField] = linkmanMap[linkmanField];
        }
      }
    }
    Widget linkmanInfoCard = LinkmanInfoCard(
      values: values,
    );
    return linkmanInfoCard;
  }

  @override
  Widget build(BuildContext context) {
    var linkmanInfoCard = _buildLinkmanInfoCard(context);
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
