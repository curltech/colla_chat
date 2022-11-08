import 'package:badges/badges.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_view.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


///好友的汇总控制器，每当消息汇总表的数据有变化时更新控制器
final DataListController<ChatSummary> linkmanChatSummaryController =
    DataListController<ChatSummary>();

///群的汇总控制器
final DataListController<ChatSummary> groupChatSummaryController =
    DataListController<ChatSummary>();

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatListWidget extends StatefulWidget with TileDataMixin {
  final GroupDataListController groupDataListController =
      GroupDataListController();
  final ChatMessageView chatMessageView = ChatMessageView();

  ChatListWidget({Key? key}) : super(key: key) {
    chatSummaryService
        .findByPartyType(PartyType.linkman.name)
        .then((List<ChatSummary> chatSummary) {
      if (chatSummary.isNotEmpty) {
        linkmanChatSummaryController.replaceAll(chatSummary);
      }
    });
    chatSummaryService
        .findByPartyType(PartyType.group.name)
        .then((List<ChatSummary> chatSummary) {
      if (chatSummary.isNotEmpty) {
        groupChatSummaryController.replaceAll(chatSummary);
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
    linkmanChatSummaryController.addListener(_update);
    groupChatSummaryController.addListener(_update);

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.define(widget.chatMessageView);
  }

  _update() {
    setState(() {});
  }

  _buildGroupDataListController() {
    Map<TileData, List<TileData>> tileData = {};
    var linkmen = linkmanChatSummaryController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name ?? '';
        var subtitle = linkman.peerId ?? '';
        var unreadNumber = linkman.unreadNumber;
        var badge = Badge(
          badgeContent: Text('$unreadNumber'),
          elevation: 0.0,
          padding: const EdgeInsets.all(0.0),
          child: myself.avatarImage,
        );
        TileData tile = TileData(
            prefix: badge,
            title: title,
            subtitle: subtitle,
            routeName: 'chat_message');
        tiles.add(tile);
      }
    }
    tileData[TileData(title: AppLocalizations.t('Linkman'))] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);

    var groups = groupChatSummaryController.data;
    tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var title = group.name ?? '';
        var subtitle = group.peerId ?? '';
        var unreadNumber = group.unreadNumber;
        var badge = Badge(
          badgeContent: Text('$unreadNumber'),
          elevation: 0.0,
          padding: const EdgeInsets.all(0.0),
          child: defaultImage,
        );
        TileData tile = TileData(
            prefix: badge,
            title: title,
            subtitle: subtitle,
            routeName: 'chat_message');
        tiles.add(tile);
      }
    }
    tileData[TileData(title: AppLocalizations.t('Group'))] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);
  }

  _onTap(int index, String title, {TileData? group}) {
    if (group != null) {
      ChatSummary? current;
      if (group.title == 'Linkman') {
        linkmanChatSummaryController.currentIndex = index;
        current = linkmanChatSummaryController.current;
      }
      if (group.title == 'Group') {
        groupChatSummaryController.currentIndex = index;
        current = groupChatSummaryController.current;
      }

      ///更新消息控制器的当前消息汇总，从而确定拥有消息的好友或者群
      chatMessageController.chatSummary = current;
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
    return AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        child: _buildGroupDataListView(context));
  }

  @override
  void dispose() {
    linkmanChatSummaryController.removeListener(_update);
    groupChatSummaryController.removeListener(_update);
    peerConnectionPoolController.removeListener(_update);
    super.dispose();
  }
}
