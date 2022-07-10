import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/chat/chat.dart';
import '../../../l10n/localization.dart';
import '../../../provider/data_list_controller.dart';
import '../../../provider/index_widget_provider.dart';
import '../../../service/chat/chat.dart';
import '../../../tool/util.dart';
import '../../../widgets/common/keep_alive_wrapper.dart';
import '../../../widgets/common/widget_mixin.dart';
import '../../../widgets/data_bind/data_group_listview.dart';
import '../../../widgets/data_bind/data_listtile.dart';
import 'chat_message_widget.dart';

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
class ChatListWidget extends StatefulWidget with TileDataMixin {
  final DataListController<ChatSummary> linkmanController =
      DataListController<ChatSummary>();
  final DataListController<ChatSummary> groupController =
      DataListController<ChatSummary>();
  final GroupDataListController groupDataListController =
      GroupDataListController();
  final ChatMessageWidget chatMessageWidget = ChatMessageWidget();

  ChatListWidget({Key? key}) : super(key: key) {
    chatSummaryService
        .findByPartyType(PartyType.linkman.name)
        .then((List<ChatSummary> chatSummary) {
      if (chatSummary.isNotEmpty) {
        linkmanController.addAll(chatSummary);
      }
    });
    chatSummaryService
        .findByPartyType(PartyType.group.name)
        .then((List<ChatSummary> chatSummary) {
      if (chatSummary.isNotEmpty) {
        groupController.addAll(chatSummary);
      }
    });
  }

  @override
  State<StatefulWidget> createState() => _ChatListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => 'Chat';
}

class _ChatListWidgetState extends State<ChatListWidget> {
  @override
  initState() {
    super.initState();
    widget.linkmanController.addListener(_update);
    widget.groupController.addListener(_update);

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.define(widget.chatMessageWidget);

    _buildGroupDataListController();
  }

  _update() {
    setState(() {});
  }

  _buildGroupDataListController() {
    Map<TileData, List<TileData>> tileData = {};
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
            routeName: 'chat_message');
        tiles.add(tile);
      }
    }
    tileData[TileData(title: 'Linkman')] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);

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
            routeName: 'chat_message');
        tiles.add(tile);
      }
    }
    tileData[TileData(title: 'Group')] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);
  }

  _onTap(int index, String title, {TileData? group}) {
    if (group != null) {
      ChatSummary? current;
      if (group.title == 'Linkman') {
        widget.linkmanController.currentIndex = index;
        current = widget.linkmanController.current;
      }
      if (group.title == 'Group') {
        widget.groupController.currentIndex = index;
        current = widget.groupController.current;
      }
      widget.chatMessageWidget.controller.chatSummary = current;
    }
  }

  Widget _buildGroupDataListView(BuildContext context) {
    _buildGroupDataListController();
    var groupDataListView = KeepAliveWrapper(
        child: GroupDataListView(
      onTap: _onTap,
      controller: widget.groupDataListController,
    ));

    return groupDataListView;
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
    return Scaffold(appBar: appBar, body: _buildGroupDataListView(context));
  }

  @override
  void dispose() {
    widget.linkmanController.removeListener(_update);
    widget.groupController.removeListener(_update);
    super.dispose();
  }
}
