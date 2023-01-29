import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_view.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
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
class LinkmanChatSummaryController extends DataListController<ChatSummary> {
  Future<void> refresh() async {
    List<ChatSummary> chatSummary =
        await chatSummaryService.findByPartyType(PartyType.linkman.name);
    if (chatSummary.isNotEmpty) {
      replaceAll(chatSummary);
    }
  }
}

final LinkmanChatSummaryController linkmanChatSummaryController =
    LinkmanChatSummaryController();

class GroupChatSummaryController extends DataListController<ChatSummary> {
  Future<void> refresh() async {
    List<ChatSummary> chatSummary =
        await chatSummaryService.findByPartyType(PartyType.group.name);
    if (chatSummary.isNotEmpty) {
      replaceAll(chatSummary);
    }
  }
}

///群的汇总控制器
final GroupChatSummaryController groupChatSummaryController =
    GroupChatSummaryController();

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatListWidget extends StatefulWidget with TileDataMixin {
  final GroupDataListController groupDataListController =
      GroupDataListController();
  final ChatMessageView chatMessageView = ChatMessageView();

  ChatListWidget({Key? key}) : super(key: key) {
    websocketPool.getDefault();
  }

  @override
  State<StatefulWidget> createState() => _ChatListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat';

  @override
  IconData get iconData => Icons.chat;

  @override
  String get title => 'Chat';
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final ValueNotifier<ConnectivityResult> _connectivityResult =
      ValueNotifier<ConnectivityResult>(ConnectivityResult.none);
  final ValueNotifier<SocketStatus> _socketStatus =
      ValueNotifier<SocketStatus>(SocketStatus.closed);
  late StreamSubscription<ConnectivityResult> subscription;

  @override
  initState() {
    super.initState();
    _reconnect();
    linkmanChatSummaryController.addListener(_update);
    linkmanChatSummaryController.refresh();
    groupChatSummaryController.addListener(_update);
    groupChatSummaryController.refresh();

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.define(widget.chatMessageView);
    websocketPool.addListener(_updateWebsocket);
    subscription =
        ConnectivityUtil.onConnectivityChanged(_onConnectivityChanged);
    Websocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      _socketStatus.value = websocket.status;
    }
  }

  ///如果没有缺省的websocket，尝试重连
  _reconnect() async {
    Websocket? websocket = websocketPool.getDefault();
    if (websocket == null) {
      await websocketPool.connect();
    }
  }

  _update() {
    setState(() {});
  }

  _updateWebsocket() {
    Websocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      _socketStatus.value = websocket.status;
    } else {
      _socketStatus.value = SocketStatus.closed;
    }
    if (_socketStatus.value == SocketStatus.connected) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Websocket status was changed to:') +
              _socketStatus.value.name);
    } else {
      DialogUtil.error(context,
          content: AppLocalizations.t('Websocket were break down'));
    }
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
    _connectivityResult.value = result;
  }

  _buildGroupDataListController() async {
    widget.groupDataListController.controllers.clear();
    Map<TileData, List<TileData>> tileData = {};
    var linkmenChatSummary = linkmanChatSummaryController.data;
    List<TileData> tiles = [];
    if (linkmenChatSummary.isNotEmpty) {
      for (var chatSummary in linkmenChatSummary) {
        var title = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var unreadNumber = chatSummary.unreadNumber;
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        if (linkman == null) {
          chatSummaryService.delete(entity: chatSummary);
          continue;
        }
        var badge = linkman.avatarImage;
        if (unreadNumber > 0) {
          badge = badges.Badge(
            badgeContent: Text('$unreadNumber',
                style: const TextStyle(color: Colors.white)),
            badgeStyle: badges.BadgeStyle(
              elevation: 0.0,
              shape: badges.BadgeShape.square,
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5.0),
            ),
            child: badge,
          );
        }
        TileData tile = TileData(
            prefix: badge,
            title: title,
            subtitle: peerId,
            dense: true,
            selected: false,
            routeName: 'chat_message');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.bookmark_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              linkmanChatSummaryController.currentIndex = index;
              await chatSummaryService.removeChatSummary(peerId);
              await chatMessageService.removeByLinkman(peerId);
              linkmanChatSummaryController.delete();
            });
        slideActions.add(deleteSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }

    tileData[TileData(title: 'Linkman')] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);

    var groupChatSummary = groupChatSummaryController.data;
    tiles = [];
    if (groupChatSummary.isNotEmpty) {
      for (var chatSummary in groupChatSummary) {
        var title = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var unreadNumber = chatSummary.unreadNumber;
        Group? group = await groupService.findCachedOneByPeerId(peerId);
        if (group == null) {
          chatSummaryService.delete(entity: chatSummary);
          continue;
        }
        var badge = group.avatarImage;
        if (unreadNumber > 0) {
          badge = badges.Badge(
            badgeContent: Text('$unreadNumber',
                style: const TextStyle(color: Colors.white)),
            badgeStyle: badges.BadgeStyle(
              elevation: 0.0,
              shape: badges.BadgeShape.square,
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5.0),
            ),
            child: badge,
          );
        }
        TileData tile = TileData(
            prefix: badge,
            title: title,
            subtitle: peerId,
            dense: true,
            selected: false,
            routeName: 'chat_message');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.bookmark_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              groupChatSummaryController.currentIndex = index;
              await chatSummaryService.removeChatSummary(peerId);
              await chatMessageService.removeByGroup(peerId);
              groupChatSummaryController.delete();
            });
        slideActions.add(deleteSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }
    tileData[TileData(title: 'Group')] = tiles;
    widget.groupDataListController.addAll(tileData: tileData);
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
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
    String title = AppLocalizations.t(widget.title);
    List<Widget> rightWidgets = [];
    var connectivityWidget = ValueListenableBuilder(
        valueListenable: _connectivityResult,
        builder: (context, value, child) {
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(
              height: 3,
            ),
            Text(_connectivityResult.value.name,
                style: const TextStyle(fontSize: 12)),
            _connectivityResult.value == ConnectivityResult.none
                ? const Icon(Icons.wifi_off, size: 20)
                : const Icon(Icons.wifi, size: 20),
          ]);
        });
    rightWidgets.add(connectivityWidget);
    rightWidgets.add(const SizedBox(
      width: 10.0,
    ));

    var wssWidget = ValueListenableBuilder(
        valueListenable: _socketStatus,
        builder: (context, value, child) {
          return InkWell(
              onTap: _socketStatus.value != SocketStatus.connected
                  ? () async {
                      //缺省的websocket如果不存在，尝试重连
                      Websocket? websocket = websocketPool.getDefault();
                      if (websocket == null) {
                        await _reconnect();
                      } else {
                        //缺省的websocket如果存在，尝试重连
                        await websocket.reconnect();
                        _updateWebsocket();
                      }
                    }
                  : null,
              child: _socketStatus.value == SocketStatus.connected
                  ? const Icon(Icons.cloud_done)
                  : const Icon(Icons.cloud_off));
        });
    rightWidgets.add(wssWidget);
    rightWidgets.add(const SizedBox(
      width: 10.0,
    ));

    return AppBarView(
        title: title,
        rightWidgets: rightWidgets,
        child: _buildGroupDataListView(context));
  }

  @override
  void dispose() {
    linkmanChatSummaryController.removeListener(_update);
    groupChatSummaryController.removeListener(_update);
    websocketPool.removeListener(_updateWebsocket);
    ConnectivityUtil.cancel(subscription);
    super.dispose();
  }
}
