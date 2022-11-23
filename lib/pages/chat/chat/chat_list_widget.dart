import 'dart:async';

import 'package:badges/badges.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_view.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  ConnectivityResult _result = ConnectivityResult.none;
  late StreamSubscription<ConnectivityResult> subscription;

  @override
  initState() {
    super.initState();
    linkmanChatSummaryController.addListener(_update);
    groupChatSummaryController.addListener(_update);

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.define(widget.chatMessageView);
    websocketPool.addListener(_update);
    subscription =
        ConnectivityUtil.onConnectivityChanged(_onConnectivityChanged);
  }

  _update() {
    setState(() {});
  }

  _onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Connectivity were break down'));
    } else {
      DialogUtil.info(context,
          content: AppLocalizations.t('Connectivity status was changed to:') +
              result.name);
    }
    setState(() {
      _result = result;
    });
  }

  _buildGroupDataListController() async {
    Map<TileData, List<TileData>> tileData = {};
    var linkmenChatSummary = linkmanChatSummaryController.data;
    List<TileData> tiles = [];
    if (linkmenChatSummary.isNotEmpty) {
      for (var chatSummary in linkmenChatSummary) {
        var title = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var unreadNumber = chatSummary.unreadNumber;
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        var badge = Badge(
          badgeContent: Text('$unreadNumber',
              style: const TextStyle(color: Colors.white)),
          elevation: 0.0,
          shape: BadgeShape.square,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5.0),
          child: ImageUtil.buildImageWidget(image: linkman!.avatar),
        );
        TileData tile = TileData(
            prefix: badge,
            title: title,
            subtitle: peerId,
            dense: true,
            routeName: 'chat_message');
        tiles.add(tile);
      }
    }
    tileData[TileData(title: AppLocalizations.t('Linkman'))] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);

    var groupChatSummary = groupChatSummaryController.data;
    tiles = [];
    if (groupChatSummary.isNotEmpty) {
      for (var chatSummary in groupChatSummary) {
        var title = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var unreadNumber = chatSummary.unreadNumber;
        Group? group = await groupService.findCachedOneByPeerId(peerId);
        var badge = Badge(
          badgeContent: Text('$unreadNumber'),
          elevation: 0.0,
          padding: const EdgeInsets.all(0.0),
          child: ImageUtil.buildImageWidget(image: group!.avatar),
        );
        TileData tile = TileData(
            prefix: badge,
            title: title,
            subtitle: peerId,
            dense: true,
            routeName: 'chat_message');
        tiles.add(tile);
      }
    }
    tileData[TileData(title: AppLocalizations.t('Group'))] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    if (group != null) {
      ChatSummary? current;
      if (group.title == AppLocalizations.t('Linkman')) {
        linkmanChatSummaryController.currentIndex = index;
        current = linkmanChatSummaryController.current;
      }
      if (group.title == AppLocalizations.t('Group')) {
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
    String title = AppLocalizations.t(widget.title);
    List<Widget> rightWidgets = [];
    var connectivityWidget =
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        height: 3,
      ),
      Text(_result.name, style: const TextStyle(fontSize: 12)),
      _result == ConnectivityResult.none
          ? const Icon(Icons.wifi_off, size: 20)
          : const Icon(Icons.wifi, size: 20),
    ]);
    rightWidgets.add(connectivityWidget);
    rightWidgets.add(const SizedBox(
      width: 10.0,
    ));
    Websocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      SocketStatus status = websocket.status;
      var wssWidget = InkWell(
          onTap: () {
            websocket.reconnect();
          },
          child: status == SocketStatus.connected
              ? const Icon(Icons.cloud_done)
              : const Icon(Icons.cloud_off));
      rightWidgets.add(wssWidget);
    }
    rightWidgets.add(const SizedBox(
      width: 10.0,
    ));

    return AppBarView(
        title: Text(title),
        rightWidgets: rightWidgets,
        child: _buildGroupDataListView(context));
  }

  @override
  void dispose() {
    linkmanChatSummaryController.removeListener(_update);
    groupChatSummaryController.removeListener(_update);
    peerConnectionPoolController.removeListener(_update);
    websocketPool.removeListener(_update);
    super.dispose();
    ConnectivityUtil.cancel(subscription);
  }
}
