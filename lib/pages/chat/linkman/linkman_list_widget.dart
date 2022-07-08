import 'package:colla_chat/pages/chat/linkman/linkman_show_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
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
import '../../../widgets/data_bind/data_group_listview.dart';

class LinkmanController extends DataListController<Linkman> {
  LinkmanController() {
    init();
  }

  init() {
    linkmanService.find().then((List<Linkman> linkmen) {
      if (linkmen.isNotEmpty) {
        addAll(linkmen);
      }
    });
  }
}

//联系人页面，带有回退回调函数
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  final LinkmanController controller = LinkmanController();
  final GroupDataListController groupDataListController =
      GroupDataListController();
  late final List<Widget> rightWidgets;
  late final LinkmanShowWidget linkmanShowWidget;

  LinkmanListWidget({Key? key}) : super(key: key) {
    linkmanShowWidget = LinkmanShowWidget(controller: controller);
    var indexWidgetProvider = IndexWidgetProvider.instance;
    indexWidgetProvider.define(linkmanShowWidget);
    rightWidgets = [
      IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = controller.current;
            if (current != null) {
              current.state = EntityState.delete;
              linkmanService.delete(current);
              controller.delete();
            }
          },
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.t('Delete')),
    ];
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
    widget.controller.addListener(_update);
    _buildGroupDataListController();
  }

  _update() {
    setState(() {});
  }

  _buildGroupDataListController() {
    var linkmen = widget.controller.data;
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
  }

  _onTap(int index, String title, {TileData? group}) {
    widget.controller.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    _buildGroupDataListController();
    var dataListView = KeepAliveWrapper(
        child: GroupDataListView(
      onTap: _onTap,
      controller: widget.groupDataListController,
    ));
    var appBar = AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      title: Text(
        AppLocalizations.instance.text(widget.title),
      ),
      actions: const [],
    );
    return Scaffold(appBar: appBar, body: dataListView);
  }

  @override
  void dispose() {
    logger.w('LinkmanListWidget dispose');
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
