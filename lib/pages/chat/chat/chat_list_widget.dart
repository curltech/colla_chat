import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_view.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityController with ChangeNotifier {
  late StreamSubscription<ConnectivityResult> subscription;
  ConnectivityResult connectivityResult = ConnectivityResult.none;

  ConnectivityController() {
    subscription =
        ConnectivityUtil.onConnectivityChanged(_onConnectivityChanged);
  }

  _onConnectivityChanged(ConnectivityResult result) {
    if (result != connectivityResult) {
      connectivityResult = result;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ConnectivityUtil.cancel(subscription);
    super.dispose();
  }
}

ConnectivityController connectivityController = ConnectivityController();

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

class ConferenceChatSummaryController extends DataListController<ChatSummary> {
  Future<void> refresh() async {
    List<ChatSummary> chatSummary =
        await chatSummaryService.findByPartyType(PartyType.conference.name);
    if (chatSummary.isNotEmpty) {
      replaceAll(chatSummary);
    }
  }
}

///会议的汇总控制器
final ConferenceChatSummaryController conferenceChatSummaryController =
    ConferenceChatSummaryController();

/// 聊天的主页面，展示可以聊天的目标对象，可以是一个人，或者是一个群，或者是一个会议
/// 选择好目标点击进入具体的聊天页面ChatMessage
class ChatListWidget extends StatefulWidget with TileDataMixin {
  ChatListWidget({Key? key}) : super(key: key) {
    websocketPool.getDefault();
    indexWidgetProvider.define(ChatMessageView());
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

class _ChatListWidgetState extends State<ChatListWidget>
    with TickerProviderStateMixin {
  final ValueNotifier<ConnectivityResult> _connectivityResult =
      ValueNotifier<ConnectivityResult>(
          connectivityController.connectivityResult);
  late ValueNotifier<SocketStatus> _socketStatus;

  final ValueNotifier<List<TileData>> _linkmanTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<List<TileData>> _groupTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<List<TileData>> _conferenceTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<int> _currentTab = ValueNotifier<int>(0);

  late TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateCurrentTab);
    _reconnect();

    linkmanChatSummaryController.addListener(_updateLinkmanChatSummary);
    linkmanChatSummaryController.refresh();
    groupChatSummaryController.addListener(_updateGroupChatSummary);
    groupChatSummaryController.refresh();
    conferenceChatSummaryController.addListener(_updateConferenceChatSummary);
    conferenceChatSummaryController.refresh();

    connectivityController.addListener(_updateConnectivity);

    Websocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      websocketPool.registerStatusChanged(
          websocket.address, _updateWebsocketStatus);
      _socketStatus = ValueNotifier<SocketStatus>(websocket.status);
    } else {
      _socketStatus = ValueNotifier<SocketStatus>(SocketStatus.closed);
    }
  }

  ///如果没有缺省的websocket，尝试重连
  _reconnect() async {
    Websocket? websocket = websocketPool.getDefault();
    if (websocket == null) {
      await websocketPool.connect();
    }
  }

  _updateCurrentTab() {
    _currentTab.value = _tabController.index;
  }

  _updateLinkmanChatSummary() {
    _buildLinkmanTileData();
  }

  _updateGroupChatSummary() {
    _buildGroupTileData();
  }

  _updateConferenceChatSummary() {
    _buildConferenceTileData();
  }

  _updateConnectivity() {
    var result = connectivityController.connectivityResult;
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

  _updateWebsocketStatus(String address, SocketStatus socketStatus) {
    var status = _socketStatus.value;
    _socketStatus.value = socketStatus;
    if (socketStatus != status) {
      if (_socketStatus.value == SocketStatus.connected) {
        DialogUtil.info(context,
            content: AppLocalizations.t(
                    'Websocket $address status was changed to:') +
                _socketStatus.value.name);
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t(
                    'Websocket $address status was changed to:') +
                _socketStatus.value.name);
      }
    }
  }

  _buildLinkmanTileData() async {
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
        var badge = linkman.avatarImage ?? AppImage.mdAppImage;
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
    _linkmanTileData.value = tiles;
  }

  _buildGroupTileData() async {
    var groupChatSummary = groupChatSummaryController.data;
    List<TileData> tiles = [];
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
        var badge = group.avatarImage ?? AppImage.mdAppImage;
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
    _groupTileData.value = tiles;
  }

  _buildConferenceTileData() async {
    var conferenceChatSummary = conferenceChatSummaryController.data;
    List<TileData> tiles = [];
    if (conferenceChatSummary.isNotEmpty) {
      for (var chatSummary in conferenceChatSummary) {
        var title = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var unreadNumber = chatSummary.unreadNumber;
        Conference? conference =
            await conferenceService.findCachedOneByConferenceId(peerId);
        if (conference == null) {
          chatSummaryService.delete(entity: chatSummary);
          continue;
        }
        var badge = conference.avatarImage ?? AppImage.mdAppImage;
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
              conferenceChatSummaryController.currentIndex = index;
              await chatSummaryService.removeChatSummary(peerId);
              await chatMessageService.removeByGroup(peerId);
              conferenceChatSummaryController.delete();
            });
        slideActions.add(deleteSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }
    _conferenceTileData.value = tiles;
  }

  _onTapLinkman(int index, String title, {String? subtitle, TileData? group}) {
    linkmanChatSummaryController.currentIndex = index;
    ChatSummary? current = linkmanChatSummaryController.current;

    ///更新消息控制器的当前消息汇总，从而确定拥有消息的好友或者群
    chatMessageController.chatSummary = current;
  }

  _onTapGroup(int index, String title, {String? subtitle, TileData? group}) {
    groupChatSummaryController.currentIndex = index;
    ChatSummary? current = groupChatSummaryController.current;

    ///更新消息控制器的当前消息汇总，从而确定拥有消息的好友或者群
    chatMessageController.chatSummary = current;
  }

  _onTapConference(int index, String title,
      {String? subtitle, TileData? group}) {
    conferenceChatSummaryController.currentIndex = index;
    ChatSummary? current = conferenceChatSummaryController.current;

    ///更新消息控制器的当前消息汇总，从而确定拥有消息的好友或者群
    chatMessageController.chatSummary = current;
  }

  Widget _buildChatListView(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: myself.avatarImage,
              // icon: Icon(Icons.person,
              //     color: value == 0 ? myself.primary : Colors.white),
              //text: AppLocalizations.t('Linkman'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Icon(Icons.group,
                  color: value == 1 ? myself.primary : Colors.white),
              //text: AppLocalizations.t('Group'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Icon(Icons.meeting_room,
                  color: value == 2 ? myself.primary : Colors.white),
              //text: AppLocalizations.t('Conference'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
    ];
    final tabBar = TabBar(
      tabs: tabs,
      controller: _tabController,
      isScrollable: false,
      indicatorColor: myself.primary.withOpacity(AppOpacity.xlOpacity),
      labelColor: Colors.white,
      padding: const EdgeInsets.all(0.0),
      labelPadding: const EdgeInsets.all(0.0),
      onTap: (int index) {
        if (index == 0) {
          linkmanChatSummaryController.refresh();
        } else if (index == 1) {
          groupChatSummaryController.refresh();
        } else if (index == 2) {
          conferenceChatSummaryController.refresh();
        }
      },
    );

    var linkmanView = ValueListenableBuilder(
        valueListenable: _linkmanTileData,
        builder: (context, value, child) {
          return DataListView(
            tileData: value,
            onTap: _onTapLinkman,
          );
        });

    var groupView = ValueListenableBuilder(
        valueListenable: _groupTileData,
        builder: (context, value, child) {
          return DataListView(
            tileData: value,
            onTap: _onTapGroup,
          );
        });

    var conferenceView = ValueListenableBuilder(
        valueListenable: _conferenceTileData,
        builder: (context, value, child) {
          return DataListView(
            tileData: value,
            onTap: _onTapConference,
          );
        });

    final tabBarView = TabBarView(
      controller: _tabController,
      children: [linkmanView, groupView, conferenceView],
    );

    return Column(
      children: [tabBar, Expanded(child: tabBarView)],
    );
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

    return KeepAliveWrapper(
        child: AppBarView(
            title: title,
            rightWidgets: rightWidgets,
            child: _buildChatListView(context)));
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateCurrentTab);
    _tabController.dispose();
    linkmanChatSummaryController.removeListener(_updateLinkmanChatSummary);
    groupChatSummaryController.removeListener(_updateGroupChatSummary);
    conferenceChatSummaryController
        .removeListener(_updateConferenceChatSummary);
    Websocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      websocketPool.unregisterStatusChanged(
          websocket.address, _updateWebsocketStatus);
    }
    super.dispose();
  }
}
