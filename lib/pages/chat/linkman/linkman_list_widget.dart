import 'package:colla_chat/pages/chat/linkman/linkman_show_widget.dart';
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
import '../../../widgets/data_bind/data_listview.dart';
import 'group_show_widget.dart';
import 'p2p_linkman_add_widget.dart';

final List<TileData> headTileData = [
  TileData(
      icon: Icon(Icons.network_cell,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'P2pLinkmanAdd',
      routeName: 'p2p_linkman_add'),
  TileData(
      icon: Icon(Icons.qr_code,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'QrcodeScanAdd',
      routeName: 'qr_code_add'),
  TileData(
      icon: Icon(Icons.contact_phone,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'ContactAdd',
      routeName: 'contact_add'),
  TileData(
      icon: Icon(Icons.request_quote,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'LinkmanRequest'),
  TileData(
      icon: Icon(Icons.tag_faces,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Tag'),
];

//联系人页面，带有回退回调函数
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  final DataListView headDataListView = DataListView(tileData: headTileData);
  final DataListController<Linkman> linkmanController =
      DataListController<Linkman>();
  final DataListController<Group> groupController = DataListController<Group>();
  final GroupDataListController groupDataListController =
      GroupDataListController();
  late final List<Widget> rightWidgets;
  late final LinkmanShowWidget linkmanShowWidget;
  late final GroupShowWidget groupShowWidget;
  late final P2pLinkmanAddWidget p2pLinkmanAddWidget;

  LinkmanListWidget({Key? key}) : super(key: key) {
    linkmanService.find().then((List<Linkman> linkmen) {
      if (linkmen.isNotEmpty) {
        linkmanController.addAll(linkmen);
      }
    });
    groupService.find().then((List<Group> groups) {
      if (groups.isNotEmpty) {
        groupController.addAll(groups);
      }
    });

    var indexWidgetProvider = IndexWidgetProvider.instance;
    linkmanShowWidget = LinkmanShowWidget(controller: linkmanController);
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

    groupShowWidget = GroupShowWidget(controller: groupController);
    indexWidgetProvider.define(groupShowWidget);

    p2pLinkmanAddWidget = P2pLinkmanAddWidget();
    indexWidgetProvider.define(p2pLinkmanAddWidget);
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

  _buildSearchTextField(BuildContext context) {
    var controller = TextEditingController();
    var searchTextField = TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: AppLocalizations.t('Search'),
          suffixIcon: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ));

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
            avatar: linkman.avatar,
            title: title,
            subtitle: subtitle,
            routeName: 'linkman_show');
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
            avatar: group.avatar,
            title: title,
            subtitle: subtitle,
            routeName: 'group_show');
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
    var groupDataListView = GroupDataListView(
      onTap: _onTap,
      controller: widget.groupDataListController,
    );
    return AppBarView(
        title: AppLocalizations.instance.text(widget.title),
        child: Column(children: [
          _buildSearchTextField(context),
          widget.headDataListView,
          Expanded(child: groupDataListView)
        ]));
  }

  @override
  void dispose() {
    logger.w('LinkmanListWidget dispose');
    widget.linkmanController.removeListener(_update);
    widget.groupController.removeListener(_update);
    super.dispose();
  }
}
