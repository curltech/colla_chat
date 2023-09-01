import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_view.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_info_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/webview/html_preview_widget.dart';
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
    int start = DateTime.now().microsecond;
    List<ChatSummary> chatSummary =
        await chatSummaryService.findByPartyType(PartyType.linkman.name);
    int end = DateTime.now().microsecond;
    logger.w('find chat summary refresh time: ${end - start} microsecond');
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
    indexWidgetProvider.define(const LinkmanInfoWidget());
    indexWidgetProvider.define(const HtmlPreviewWidget());
    indexWidgetProvider.define(const LinkmanGroupEditWidget());
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
  final ValueNotifier<SocketStatus> _socketStatus =
      ValueNotifier<SocketStatus>(SocketStatus.none);

  final ValueNotifier<List<TileData>> _linkmanTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<List<TileData>> _groupTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<List<TileData>> _conferenceTileData =
      ValueNotifier<List<TileData>>([]);
  final ValueNotifier<int> _currentTab = ValueNotifier<int>(0);

  TabController? _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_updateCurrentTab);
    _reconnect();

    linkmanChatSummaryController.addListener(_updateLinkmanChatSummary);
    linkmanChatSummaryController.refresh();
    groupChatSummaryController.addListener(_updateGroupChatSummary);
    groupChatSummaryController.refresh();
    conferenceChatSummaryController.addListener(_updateConferenceChatSummary);
    conferenceChatSummaryController.refresh();

    connectivityController.addListener(_updateConnectivity);

    Websocket? websocket = websocketPool.defaultWebsocket;
    if (websocket != null) {
      websocketPool.registerStatusChanged(
          websocket.address, _updateWebsocketStatus);
      _socketStatus.value = websocket.status;
    } else {
      _socketStatus.value = SocketStatus.closed;
    }
  }

  ///网络连通的情况下，如果没有缺省的websocket，尝试重连websocket
  _reconnect() async {
    if (_connectivityResult.value != ConnectivityResult.none &&
        (_socketStatus.value != SocketStatus.connected ||
            _socketStatus.value != SocketStatus.reconnecting)) {
      Websocket? websocket = websocketPool.getDefault();
      if (websocket == null) {
        await websocketPool.connect();
      }
    }
  }

  _updateCurrentTab() {
    _currentTab.value = _tabController!.index;
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
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Connectivity were break down'));
      }
    } else {
      _reconnect();
      if (mounted) {
        DialogUtil.info(context,
            content: AppLocalizations.t('Connectivity status was changed to:') +
                result.name);
      }
    }
    _connectivityResult.value = result;
  }

  _updateWebsocketStatus(String address, SocketStatus socketStatus) {
    var status = _socketStatus.value;
    _socketStatus.value = socketStatus;
    if (socketStatus != status) {
      ///websocket连接后所有的friend的webrtc重连
      if (_socketStatus.value == SocketStatus.connected) {
        _reconnectWebrtc();
        if (mounted) {
          DialogUtil.info(context,
              content:
                  '$address ${AppLocalizations.t('Websocket status was changed to:')}${_socketStatus.value.name}');
        }
      } else {
        if (mounted) {
          // DialogUtil.error(context,
          //     content:
          //         '$address ${AppLocalizations.t('Websocket status was changed to:')}${_socketStatus.value.name}');
        }
      }
    }
  }

  ///所有的friend的webrtc重连
  _reconnectWebrtc() async {
    List<Linkman> linkmen = await linkmanService
        .find(where: 'linkmanStatus=?', whereArgs: [LinkmanStatus.friend.name]);
    if (linkmen.isNotEmpty) {
      for (Linkman linkman in linkmen) {
        String peerId = linkman.peerId;
        if (myself.peerId == peerId) {
          continue;
        }
        List<AdvancedPeerConnection> advancedPeerConnections =
            await peerConnectionPool.get(peerId);
        //如果连接不存在，则创建新连接
        if (advancedPeerConnections.isEmpty) {
          peerConnectionPool.createOffer(peerId);
        }
      }
    }
  }

  String _buildSubtitle(
      {required String subMessageType,
      String? title,
      String? contentType,
      String? content}) {
    String? subtitle;
    if (subMessageType == ChatMessageSubType.chat.name) {
      if (contentType == null ||
          contentType == ChatMessageContentType.text.name) {
        if (content != null && content.isNotEmpty) {
          subtitle = chatMessageService.recoverContent(content);
        }
      }
      if (contentType == ChatMessageContentType.location.name &&
          subtitle != null) {
        Map<String, dynamic> map = JsonUtil.toJson(subtitle);
        String? address = map['address'];
        address = address ?? '';
        subtitle = address;
      }
      if (subtitle == null) {
        if (title != null && title.isNotEmpty) {
          subtitle = title;
        }
      }
    } else {
      subtitle = AppLocalizations.t(subMessageType);
    }
    return subtitle ?? '';
  }

  Widget _buildBadge(int unreadNumber, {Widget? avatarImage}) {
    var badge = avatarImage ?? AppImage.mdAppImage;
    if (unreadNumber > 0) {
      badge = badges.Badge(
        position: BadgePosition.topEnd(),
        stackFit: StackFit.loose,
        badgeContent: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 12,
            ),
            child: Center(
                child: CommonAutoSizeText('$unreadNumber',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)))),
        badgeStyle: const badges.BadgeStyle(
          elevation: 0.0,
          shape: badges.BadgeShape.square,
          borderRadius: BorderRadius.horizontal(
              left: Radius.circular(8), right: Radius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 2.0),
        ),
        child: badge,
      );
    }

    return badge;
  }

  _buildLinkmanTileData() async {
    var linkmenChatSummary = linkmanChatSummaryController.data;
    List<TileData> tiles = [];
    if (linkmenChatSummary.isNotEmpty) {
      for (var chatSummary in linkmenChatSummary) {
        var title = chatSummary.title ?? '';
        var name = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var subtitle = peerId;
        var subMessageType = chatSummary.subMessageType;
        var sendReceiveTime = chatSummary.sendReceiveTime;
        if (sendReceiveTime != null) {
          sendReceiveTime = DateUtil.formatEasyRead(sendReceiveTime);
        } else {
          sendReceiveTime = '';
        }
        subtitle = _buildSubtitle(
            subMessageType: subMessageType ?? '',
            title: title,
            contentType: chatSummary.contentType,
            content: chatSummary.content);
        var unreadNumber = chatSummary.unreadNumber;
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        if (linkman == null) {
          //chatSummaryService.delete(entity: chatSummary);
          continue;
        }
        var linkmanStatus =
            linkman.linkmanStatus ?? LinkmanStatus.stranger.name;
        linkmanStatus = AppLocalizations.t(linkmanStatus);
        if (peerId == myself.peerId) {
          linkmanStatus = AppLocalizations.t('Me');
        }
        name = '$name($linkmanStatus)';
        var avatarImage = linkman.avatarImage;
        if (linkmanStatus == LinkmanStatus.chatGPT.name) {
          avatarImage = avatarImage ??
              ImageUtil.buildImageWidget(
                  image: 'assets/images/openai.png',
                  width: AppImageSize.mdSize,
                  height: AppImageSize.mdSize);
        }
        var badge = _buildBadge(unreadNumber, avatarImage: avatarImage);

        TileData tile = _buildTile(badge, name, sendReceiveTime, subtitle,
            peerId, linkmanChatSummaryController);
        tiles.add(tile);
      }
    }
    _linkmanTileData.value = tiles;
  }

  TileData _buildTile(
      Widget badge,
      String name,
      String sendReceiveTime,
      String subtitle,
      String peerId,
      DataListController<ChatSummary> chatSummaryController) {
    TileData tile = TileData(
        prefix: badge,
        title: name,
        titleTail: sendReceiveTime,
        subtitle: subtitle,
        dense: true,
        selected: false,
        isThreeLine: false,
        routeName: 'chat_message');
    List<TileData> slideActions = [];
    TileData deleteSlideAction = TileData(
        title: 'Delete',
        prefix: Icons.bookmark_remove,
        onTap: (int index, String label, {String? subtitle}) async {
          chatSummaryController.currentIndex = index;
          await chatSummaryService.removeChatSummary(peerId);
          await chatMessageService.removeByLinkman(peerId);
          chatSummaryController.delete();
        });
    slideActions.add(deleteSlideAction);
    tile.slideActions = slideActions;

    return tile;
  }

  _buildGroupTileData() async {
    var groupChatSummary = groupChatSummaryController.data;
    List<TileData> tiles = [];
    if (groupChatSummary.isNotEmpty) {
      for (var chatSummary in groupChatSummary) {
        var title = chatSummary.title ?? '';
        var name = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var subtitle = peerId;
        var subMessageType = chatSummary.subMessageType;
        var sendReceiveTime = chatSummary.sendReceiveTime ?? '';
        sendReceiveTime = DateUtil.formatEasyRead(sendReceiveTime);
        subtitle = _buildSubtitle(
            subMessageType: subMessageType!,
            title: title,
            contentType: chatSummary.contentType,
            content: chatSummary.content);
        var unreadNumber = chatSummary.unreadNumber;
        Group? group = await groupService.findCachedOneByPeerId(peerId);
        if (group == null) {
          chatSummaryService.delete(entity: chatSummary);
          continue;
        }
        var badge = _buildBadge(unreadNumber, avatarImage: group.avatarImage);

        TileData tile = _buildTile(badge, name, sendReceiveTime, subtitle,
            peerId, groupChatSummaryController);
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
        var title = chatSummary.title ?? '';
        var name = chatSummary.name ?? '';
        var peerId = chatSummary.peerId ?? '';
        var subtitle = peerId;
        var subMessageType = chatSummary.subMessageType;
        var sendReceiveTime = chatSummary.sendReceiveTime;
        sendReceiveTime = sendReceiveTime != null
            ? DateUtil.formatEasyRead(sendReceiveTime)
            : '';
        subtitle = _buildSubtitle(
            subMessageType: subMessageType!,
            title: title,
            contentType: chatSummary.contentType,
            content: chatSummary.content);
        var unreadNumber = chatSummary.unreadNumber;
        Conference? conference =
            await conferenceService.findCachedOneByConferenceId(peerId);
        if (conference == null) {
          chatSummaryService.delete(entity: chatSummary);
          continue;
        }
        var badge =
            _buildBadge(unreadNumber, avatarImage: conference.avatarImage);
        TileData tile = _buildTile(badge, name, sendReceiveTime, subtitle,
            peerId, conferenceChatSummaryController);
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
              icon: Tooltip(
                  message: AppLocalizations.t('Linkman'),
                  child: value == 0
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: AppIconSize.mdSize,
                        )
                      : const Icon(Icons.person, color: Colors.white)),
              //text: AppLocalizations.t('Linkman'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Tooltip(
                  message: AppLocalizations.t('Group'),
                  child: value == 1
                      ? const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: AppIconSize.mdSize,
                        )
                      : const Icon(Icons.group, color: Colors.white)),
              //text: AppLocalizations.t('Group'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Tooltip(
                  message: AppLocalizations.t('Conference'),
                  child: value == 2
                      ? const Icon(
                          Icons.video_chat,
                          color: Colors.white,
                          size: AppIconSize.mdSize,
                        )
                      : const Icon(Icons.video_chat, color: Colors.white)),
              //text: AppLocalizations.t('Conference'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
    ];
    final tabBar = TabBar(
      tabs: tabs,
      controller: _tabController,
      isScrollable: false,
      indicatorColor: Colors.white,
      dividerColor: Colors.white.withOpacity(0),
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
          return Tooltip(
              message: AppLocalizations.t('Network status'),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _connectivityResult.value == ConnectivityResult.none
                    ? const Icon(
                        Icons.wifi_off,
                        color: Colors.red,
                      )
                    : const Icon(
                        Icons.wifi,
                        //color: Colors.green,
                      ),
                CommonAutoSizeText(_connectivityResult.value.name,
                    style: const TextStyle(fontSize: 12)),
              ]));
        });
    rightWidgets.add(connectivityWidget);
    rightWidgets.add(const SizedBox(
      width: 10.0,
    ));

    var wssWidget = ValueListenableBuilder(
        valueListenable: _socketStatus,
        builder: (context, value, child) {
          return IconButton(
              tooltip: AppLocalizations.t('Websocket status'),
              onPressed: _socketStatus.value != SocketStatus.connected
                  ? () async {
                      //缺省的websocket如果不存在，尝试重连
                      Websocket? websocket = websocketPool.getDefault();
                      if (websocket == null) {
                        await _reconnect();
                      } else {
                        //缺省的websocket如果存在，尝试重连
                        if (websocket.status != SocketStatus.connected) {
                          await websocket.reconnect();
                        } else {
                          _socketStatus.value = SocketStatus.connected;
                        }
                      }
                    }
                  : null,
              icon: _socketStatus.value == SocketStatus.connected
                  ? const Icon(
                      Icons.cloud_done,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.cloud_off,
                      color: Colors.red,
                    ));
        });
    rightWidgets.add(wssWidget);
    rightWidgets.add(const SizedBox(
      width: 10.0,
    ));

    return AppBarView(
        title: title,
        rightWidgets: rightWidgets,
        child: _buildChatListView(context));
  }

  @override
  void dispose() {
    _tabController!.removeListener(_updateCurrentTab);
    _tabController!.dispose();
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
