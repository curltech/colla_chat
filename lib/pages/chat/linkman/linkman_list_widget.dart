import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_info_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_info_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';


final DataListController<Linkman> linkmanController =
    DataListController<Linkman>();
final DataListController<Group> groupController = DataListController<Group>();

//联系人和群的查询界面
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  final GroupDataListController groupDataListController =
      GroupDataListController();
  late final LinkmanInfoWidget linkmanInfoWidget;
  late final LinkmanGroupInfoWidget groupInfoWidget;
  late final LinkmanAddWidget linkmanAddWidget;
  late final GroupAddWidget groupAddWidget;

  LinkmanListWidget({Key? key}) : super(key: key) {
    linkmanInfoWidget = LinkmanInfoWidget();
    indexWidgetProvider.define(linkmanInfoWidget);

    groupInfoWidget = LinkmanGroupInfoWidget();
    indexWidgetProvider.define(groupInfoWidget);

    linkmanAddWidget = LinkmanAddWidget();
    indexWidgetProvider.define(linkmanAddWidget);

    groupAddWidget = GroupAddWidget();
    indexWidgetProvider.define(groupAddWidget);
  }

  @override
  State<StatefulWidget> createState() => _LinkmanListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman';

  @override
  Icon get icon => const Icon(Icons.group);

  @override
  String get title => 'Linkman';
}

class _LinkmanListWidgetState extends State<LinkmanListWidget> {
  @override
  initState() {
    super.initState();
    linkmanController.addListener(_update);
    groupController.addListener(_update);
    _buildGroupDataListController();
  }

  _update() {
    setState(() {});
  }

  _search(String key) async {
    List<Linkman> linkmen = await linkmanService.search(key);
    linkmanController.replaceAll(linkmen);
    List<Group> groups = await groupService.search(key);
    groupController.replaceAll(groups);
  }

  _buildSearchTextField(BuildContext context) {
    var controller = TextEditingController();
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.black.withOpacity(0.1),
              filled: true,
              border: InputBorder.none,
              labelText: AppLocalizations.t('Search'),
              suffixIcon: IconButton(
                onPressed: () {
                  _search(controller.text);
                },
                icon: const Icon(Icons.search),
              ),
            )));

    return searchTextField;
  }

  _buildGroupDataListController() {
    var linkmen = linkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name;
        var subtitle = linkman.peerId;
        TileData tile = TileData(
            prefix: linkman.avatar,
            title: title,
            subtitle: subtitle,
            routeName: 'linkman_info');
        tiles.add(tile);
      }
    }
    var keyTile = TileData(title: 'Linkman');
    widget.groupDataListController.add(keyTile, tiles);

    var groups = groupController.data;
    tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var title = group.name;
        var subtitle = group.peerId;
        TileData tile = TileData(
            prefix: group.avatar,
            title: title,
            subtitle: subtitle,
            routeName: 'linkman_group_edit');
        tiles.add(tile);
      }
    }
    keyTile = TileData(title: 'Group');
    widget.groupDataListController.add(keyTile, tiles);
  }

  _onTap(int index, String title, {TileData? group}) {
    if (group != null) {
      if (group.title == 'Linkman') {
        linkmanController.currentIndex = index;
      }
      if (group.title == 'Group') {
        groupController.currentIndex = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var rightWidgets = [
      IconButton(
          onPressed: () {
            indexWidgetProvider.push('linkman_add');
          },
          icon: const Icon(Icons.person_add),
          tooltip: AppLocalizations.t('Add linkman')),
      IconButton(
          onPressed: () {
            indexWidgetProvider.push('group_add');
          },
          icon: const Icon(Icons.group_add),
          tooltip: AppLocalizations.t('Add group')),
    ];
    _buildGroupDataListController();
    var groupDataListView = Container(
        padding: const EdgeInsets.all(10.0),
        child: GroupDataListView(
          onTap: _onTap,
          controller: widget.groupDataListController,
        ));
    return AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        rightWidgets: rightWidgets,
        child: Column(children: [
          _buildSearchTextField(context),
          Expanded(child: groupDataListView)
        ]));
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    groupController.removeListener(_update);
    super.dispose();
  }
}
