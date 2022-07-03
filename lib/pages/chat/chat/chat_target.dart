import 'package:flutter/material.dart';

import '../../../entity/chat/contact.dart';
import '../../../l10n/localization.dart';
import '../../../provider/data_list_controller.dart';
import '../../../tool/util.dart';
import '../../../widgets/common/data_group_listview.dart';
import '../../../widgets/common/data_listtile.dart';
import '../../../widgets/common/keep_alive_wrapper.dart';
import '../../../widgets/common/widget_mixin.dart';

final Map<TileData, List<TileData>> mockTileData = {
  TileData(title: '群'): [
    TileData(
        title: '家庭群',
        subtitle: '美国留学',
        suffix: DateUtil.formatChinese(DateUtil.currentDate())),
    TileData(
        title: 'MBA群',
        subtitle: '上海团购',
        suffix: DateUtil.formatChinese('2022-06-20T09:23:45.000Z')),
  ],
  TileData(title: '个人'): [
    TileData(
        title: '李志群',
        subtitle: '',
        suffix: DateUtil.formatChinese('2022-06-21T16:23:45.000Z')),
    TileData(
        title: '胡百水',
        subtitle: '',
        suffix: DateUtil.formatChinese('2022-06-20T21:23:45.000Z')),
  ]
};

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatTarget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> linkmanController =
      DataListController<Linkman>();
  final DataListController<Group> groupController = DataListController<Group>();

  ChatTarget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatTargetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => 'Chat';
}

class _ChatTargetState extends State<ChatTarget> {
  late KeepAliveWrapper<GroupDataListView> groupDataListView;

  @override
  initState() {
    super.initState();
    widget.linkmanController.addListener(() {
      setState(() {});
    });
    widget.groupController.addListener(() {
      setState(() {});
    });

    Map<TileData, List<TileData>> chatTileData = {};
    var linkmen = widget.linkmanController.data;
    var linkmanTiles = _convertLinkman(linkmen);
    chatTileData[TileData(title: 'linkman')] = linkmanTiles;
    var groups = widget.groupController.data;
    var groupTiles = _convertGroup(groups);
    chatTileData[TileData(title: 'group')] = groupTiles;

    groupDataListView =
        KeepAliveWrapper(child: GroupDataListView(tileData: chatTileData));
  }

  List<TileData> _convertLinkman(List<Linkman> linkmen) {
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name ?? '';
        var subtitle = linkman.peerId ?? '';
        TileData tile = TileData(
            title: title, subtitle: subtitle, routeName: 'peer_client_edit');
        tiles.add(tile);
      }
    }

    return tiles;
  }

  List<TileData> _convertGroup(List<Group> groups) {
    List<TileData> tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var title = group.name ?? '';
        var subtitle = group.peerId ?? '';
        TileData tile = TileData(
            title: title, subtitle: subtitle, routeName: 'peer_client_edit');
        tiles.add(tile);
      }
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      title: Text(
        AppLocalizations.instance.text(widget.title),
      ),
      actions: const [],
    );
    return Scaffold(appBar: appBar, body: groupDataListView);
  }
}
