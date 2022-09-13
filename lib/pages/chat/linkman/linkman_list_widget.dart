import 'package:colla_chat/pages/chat/linkman/group/group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_info_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:flutter/material.dart';

import '../../../../entity/base.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listtile.dart';
import '../../../entity/chat/contact.dart';
import '../../../service/chat/contact.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/data_bind/data_group_listview.dart';
import 'group/group_info_widget.dart';
import 'linkman/p2p_linkman_add_widget.dart';

final List<AppBarPopupMenu> appBarPopupMenus = [
  AppBarPopupMenu(
      icon: Icon(Icons.person_add,
          color: appDataProvider.themeData.colorScheme.primary),
      title: 'P2pLinkmanAdd',
      onPressed: () {
        indexWidgetProvider.push('p2p_linkman_add');
      }),
  AppBarPopupMenu(
      icon: Icon(Icons.qr_code,
          color: appDataProvider.themeData.colorScheme.primary),
      title: 'QrcodeScanAdd',
      onPressed: () {
        indexWidgetProvider.push('qr_code_add');
      }),
  AppBarPopupMenu(
      icon: Icon(Icons.contact_phone,
          color: appDataProvider.themeData.colorScheme.primary),
      title: 'ContactAdd',
      onPressed: () {
        indexWidgetProvider.push('contact_add');
      }),
  AppBarPopupMenu(
      icon: Icon(Icons.contact_mail,
          color: appDataProvider.themeData.colorScheme.primary),
      title: 'LinkmanRequest',
      onPressed: () {
        indexWidgetProvider.push('linkman_request');
      }),
  AppBarPopupMenu(
      icon: Icon(Icons.group_add,
          color: appDataProvider.themeData.colorScheme.primary),
      title: 'GroupAdd',
      onPressed: () {
        indexWidgetProvider.push('group_add');
      }),
];

//联系人页面，带有回退回调函数
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> linkmanController =
      DataListController<Linkman>();
  final DataListController<Group> groupController = DataListController<Group>();
  final GroupDataListController groupDataListController =
      GroupDataListController();
  late final List<Widget> rightWidgets;
  late final LinkmanInfoWidget linkmanShowWidget;
  late final GroupInfoWidget groupShowWidget;
  late final P2pLinkmanAddWidget p2pLinkmanAddWidget;
  late final GroupAddWidget groupAddWidget;

  LinkmanListWidget({Key? key}) : super(key: key) {
    linkmanShowWidget = LinkmanInfoWidget(controller: linkmanController);
    indexWidgetProvider.define(linkmanShowWidget);
    rightWidgets = [
      IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = linkmanController.current;
            if (current != null) {
              current.state = EntityState.delete;
              linkmanService.delete(current);
              linkmanController.delete();
            }
          },
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.t('Delete')),
    ];

    groupShowWidget = GroupInfoWidget(controller: groupController);
    indexWidgetProvider.define(groupShowWidget);

    p2pLinkmanAddWidget = P2pLinkmanAddWidget();
    indexWidgetProvider.define(p2pLinkmanAddWidget);

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
    widget.linkmanController.addListener(_update);
    widget.groupController.addListener(_update);
    _buildGroupDataListController();
  }

  _update() {
    setState(() {});
  }

  _search(String key) async {
    List<Linkman> linkmen = await linkmanService.search(key);
    widget.linkmanController.replaceAll(linkmen);
    List<Group> groups = await groupService.search(key);
    widget.groupController.replaceAll(groups);
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
    var linkmen = widget.linkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name ?? '';
        var subtitle = linkman.peerId ?? '';
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

    var groups = widget.groupController.data;
    tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var title = group.name ?? '';
        var subtitle = group.peerId ?? '';
        TileData tile = TileData(
            prefix: group.avatar,
            title: title,
            subtitle: subtitle,
            routeName: 'group_info');
        tiles.add(tile);
      }
    }
    keyTile = TileData(title: 'Group');
    widget.groupDataListController.add(keyTile, tiles);
  }

  _onTap(int index, String title, {TileData? group}) {
    if (group != null) {
      if (group.title == 'Linkman') {
        widget.linkmanController.currentIndex = index;
      }
      if (group.title == 'Group') {
        widget.groupController.currentIndex = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildGroupDataListController();
    var groupDataListView = Container(
        padding: const EdgeInsets.all(10.0),
        child: GroupDataListView(
          onTap: _onTap,
          controller: widget.groupDataListController,
        ));
    return AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        rightPopupMenus: appBarPopupMenus,
        child: Column(children: [
          _buildSearchTextField(context),
          Expanded(child: groupDataListView)
        ]));
  }

  @override
  void dispose() {
    widget.linkmanController.removeListener(_update);
    widget.groupController.removeListener(_update);
    super.dispose();
  }
}
