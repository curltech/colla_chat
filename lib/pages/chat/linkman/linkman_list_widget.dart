import 'package:badges/badges.dart' as badges;
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_add_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LinkmanController extends DataListController<Linkman> {
  changeLinkmanStatus(Linkman linkman, LinkmanStatus status) async {
    int id = linkman.id!;
    await linkmanService.update({'id': id, 'linkmanStatus': status.name});
    linkmanService.linkmen.remove(linkman.peerId);
    linkman.linkmanStatus = status.name;
    data.assignAll(data);
  }

  changeSubscriptStatus(Linkman linkman, LinkmanStatus status) async {
    int id = linkman.id!;
    await linkmanService.update({'id': id, 'subscriptStatus': status.name});
    linkmanService.linkmen.remove(linkman.peerId);
    linkman.subscriptStatus = status.name;
    data.assignAll(data);
  }
}

final LinkmanController linkmanController = LinkmanController();
final DataListController<Group> groupController = DataListController<Group>();
final DataListController<Conference> conferenceController =
    DataListController<Conference>();

///联系人和群的查询界面
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  final LinkmanAddWidget linkmanAddWidget = LinkmanAddWidget();
  final LinkmanEditWidget linkmanEditWidget = LinkmanEditWidget();
  final ConferenceShowWidget conferenceShowWidget = ConferenceShowWidget();
  late final List<TileData> linkmanTileData;

  LinkmanListWidget({super.key}) {
    indexWidgetProvider.define(linkmanEditWidget);
    indexWidgetProvider.define(linkmanAddWidget);
    indexWidgetProvider.define(conferenceShowWidget);
    List<TileDataMixin> mixins = [
      linkmanEditWidget,
      linkmanAddWidget,
      conferenceShowWidget,
    ];
    linkmanTileData = TileData.from(mixins);
    for (var tile in linkmanTileData) {
      tile.dense = false;
      tile.selected = false;
    }
  }

  @override
  State<StatefulWidget> createState() => _LinkmanListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman';

  @override
  IconData get iconData => Icons.group;

  @override
  String get title => 'Linkman';

  @override
  String? get information => null;
}

class _LinkmanListWidgetState extends State<LinkmanListWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _linkmanTextController = TextEditingController();
  final TextEditingController _groupTextController = TextEditingController();
  final TextEditingController _conferenceTextController =
      TextEditingController();

  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  initState() {
    super.initState();
    _searchLinkman(_linkmanTextController.text);
  }

  _searchLinkman(String key) async {
    List<Linkman> linkmen = await linkmanService.search(key);
    linkmanController.replaceAll(linkmen);
  }

  _searchGroup(String key) async {
    List<Group> groups = await groupService.search(key);
    groupController.replaceAll(groups);
  }

  _searchConference(String key) async {
    List<Conference> conferences = await conferenceService.search(key);
    conferenceController.replaceAll(conferences);
  }

  _buildLinkmanSearchTextField(BuildContext context) {
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: CommonTextFormField(
          controller: _linkmanTextController,
          keyboardType: TextInputType.text,
          //labelText: AppLocalizations.t('Search'),
          suffixIcon: IconButton(
            onPressed: () {
              _searchLinkman(_linkmanTextController.text);
            },
            icon: Icon(
              Icons.search,
              color: myself.primary,
            ),
          ),
        ));

    return searchTextField;
  }

  _buildGroupSearchTextField(BuildContext context) {
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: CommonTextFormField(
          controller: _groupTextController,
          keyboardType: TextInputType.text,
          //labelText: AppLocalizations.t('Search'),
          suffixIcon: IconButton(
            onPressed: () {
              _searchGroup(_groupTextController.text);
            },
            icon: Icon(
              Icons.search,
              color: myself.primary,
            ),
          ),
        ));

    return searchTextField;
  }

  _buildConferenceSearchTextField(BuildContext context) {
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: CommonTextFormField(
          controller: _conferenceTextController,
          keyboardType: TextInputType.text,
          //labelText: AppLocalizations.t('Search'),
          suffixIcon: IconButton(
            onPressed: () {
              _searchConference(_conferenceTextController.text);
            },
            icon: Icon(
              Icons.search,
              color: myself.primary,
            ),
          ),
        ));

    return searchTextField;
  }

  Widget _buildBadge(int connectionNum, {Widget? avatarImage}) {
    var badge = avatarImage ?? AppImage.mdAppImage;
    Widget? child;
    if (connectionNum > 0) {
      child = const Center(
          child: CommonAutoSizeText('',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)));
    }
    badge = badges.Badge(
      position: badges.BadgePosition.topEnd(),
      stackFit: StackFit.loose,
      badgeContent: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 10,
          ),
          child: child),
      badgeStyle: badges.BadgeStyle(
        elevation: 0.0,
        badgeColor: connectionNum == 0 ? Colors.red : Colors.green,
        shape: badges.BadgeShape.square,
        borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(8), right: Radius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 2.0),
      ),
      child: badge,
    );

    return badge;
  }

  //将linkman和group数据转换从列表显示数据
  List<TileData> _buildLinkmanTileData() {
    var linkmen = linkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var name = linkman.name;
        var peerId = linkman.peerId;
        String? linkmanStatus = linkman.linkmanStatus ?? LinkmanStatus.S.name;
        linkmanStatus = AppLocalizations.t(linkmanStatus);
        if (peerId == myself.peerId) {
          linkmanStatus = AppLocalizations.t(LinkmanStatus.M.name);
        }
        if (linkman.subscriptStatus == LinkmanStatus.C.name) {
          linkmanStatus =
              '$linkmanStatus/${AppLocalizations.t(LinkmanStatus.C.name)}';
        }
        Widget? prefix = linkman.avatarImage;
        String routeName = 'linkman_edit';
        if (linkman.linkmanStatus == LinkmanStatus.G.name) {
          // prefix = prefix ??
          //     ImageUtil.buildImageWidget(
          //         image: 'assets/image/ollama.png',
          //         width: AppIconSize.lgSize,
          //         height: AppIconSize.lgSize);
          // routeName = 'llm_chat_add';
        }
        prefix = prefix ?? AppImage.mdAppImage;
        int connectionNum = 0;
        List<AdvancedPeerConnection>? connections =
            peerConnectionPool.getConnected(peerId);
        if (connections.isNotEmpty) {
          connectionNum = connections.length;
        }
        TileData tile = TileData(
            prefix: _buildBadge(connectionNum, avatarImage: prefix),
            title: name,
            subtitle: linkmanStatus,
            selected: false,
            routeName: routeName,
            onTap: (int index, String title, {String? subtitle}) {
              linkmanNotifier.value = linkman;
            });
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.person_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              bool? confirm = await DialogUtil.confirm(
                  content:
                      '${AppLocalizations.t('Do you want delete linkman')} ${linkman.name}');
              if (confirm != true) {
                return;
              }
              linkmanController.setCurrentIndex = index;
              await linkmanService.removeByPeerId(linkman.peerId);
              await chatSummaryService.removeChatSummary(linkman.peerId);
              await chatMessageService.removeByLinkman(linkman.peerId);
              linkmanController.delete();
              if (mounted) {
                DialogUtil.info(
                    content:
                        '${AppLocalizations.t('Linkman:')} ${linkman.name}${AppLocalizations.t(' is deleted')}');
              }
            });

        if (peerId != myself.peerId) {
          slideActions.add(deleteSlideAction);
        }

        TileData requestSlideAction = TileData(
            title: 'Request add friend',
            prefix: Icons.request_quote_outlined,
            onTap: (int index, String title, {String? subtitle}) async {
              if (mounted) {
                String? tip = await DialogUtil.showTextFormField(
                    title: AppLocalizations.t('Request add friend'),
                    tip: AppLocalizations.t('I am ') + myself.name!,
                    content: AppLocalizations.t(
                        'Please input request add friend tip'));
                if (tip != null) {
                  await linkmanService.addFriend(linkman.peerId, tip);
                  if (mounted) {
                    DialogUtil.info(
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is requested add me as friend')}');
                  }
                }
              }
            });
        if (peerId != myself.peerId && linkmanStatus != LinkmanStatus.G.name) {
          slideActions.add(requestSlideAction);
        }
        TileData chatSlideAction = TileData(
            title: 'Chat',
            prefix: Icons.chat,
            onTap: (int index, String label, {String? subtitle}) async {
              ChatSummary? chatSummary =
                  await chatSummaryService.findOneByPeerId(linkman.peerId);
              chatSummary ??= await chatSummaryService.upsertByLinkman(linkman);
              chatMessageController.chatSummary = chatSummary;
              indexWidgetProvider.push('chat_message');
            });
        slideActions.add(chatSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        if (peerId != myself.peerId && linkmanStatus != LinkmanStatus.G.name) {
          if (linkman.linkmanStatus == LinkmanStatus.F.name) {
            endSlideActions.add(TileData(
                title: 'Remove friend',
                prefix: Icons.person_remove_outlined,
                onTap: (int index, String title, {String? subtitle}) async {
                  bool? confirm = await DialogUtil.confirm(
                      content:
                          '${AppLocalizations.t('Do you want remove friend')} ${linkman.name}');
                  if (confirm != true) {
                    return;
                  }
                  linkmanController.changeLinkmanStatus(
                      linkman, LinkmanStatus.S);
                  if (mounted) {
                    DialogUtil.info(
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is removed friend')}');
                  }
                }));
          }
          if (linkman.linkmanStatus == null ||
              linkman.linkmanStatus == LinkmanStatus.N.name ||
              linkman.linkmanStatus == LinkmanStatus.S.name) {
            endSlideActions.add(TileData(
                title: 'Add friend',
                prefix: Icons.person_add_outlined,
                onTap: (int index, String title, {String? subtitle}) async {
                  bool? confirm = await DialogUtil.confirm(
                      content:
                          '${AppLocalizations.t('Do you want add friend')} ${linkman.name}');
                  if (confirm != true) {
                    return;
                  }
                  linkmanController.changeLinkmanStatus(
                      linkman, LinkmanStatus.F);
                  if (mounted) {
                    DialogUtil.info(
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is added friend')}');
                  }
                }));
          }
          if (linkman.linkmanStatus == LinkmanStatus.B.name) {
            endSlideActions.add(
              TileData(
                  title: 'Remove blacklist',
                  prefix: Icons.person_outlined,
                  onTap: (int index, String title, {String? subtitle}) async {
                    bool? confirm = await DialogUtil.confirm(
                        content:
                            '${AppLocalizations.t('Do you want remove blacklist')} ${linkman.name}');
                    if (confirm != true) {
                      return;
                    }
                    linkmanController.changeLinkmanStatus(
                        linkman, LinkmanStatus.S);
                    if (mounted) {
                      DialogUtil.info(
                          content:
                              '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is removed blacklist')}');
                    }
                  }),
            );
          } else {
            endSlideActions.add(TileData(
                title: 'Add blacklist',
                prefix: Icons.person_off,
                onTap: (int index, String title, {String? subtitle}) async {
                  bool? confirm = await DialogUtil.confirm(
                      content:
                          '${AppLocalizations.t('Do you want add blacklist')} ${linkman.name}');
                  if (confirm != true) {
                    return;
                  }
                  linkmanController.changeLinkmanStatus(
                      linkman, LinkmanStatus.B);
                  if (mounted) {
                    DialogUtil.info(
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is added blacklist')}');
                  }
                }));
          }
          if (linkman.subscriptStatus == LinkmanStatus.C.name) {
            endSlideActions.add(
              TileData(
                  title: 'Remove subscript',
                  prefix: Icons.unsubscribe,
                  onTap: (int index, String title, {String? subtitle}) async {
                    bool? confirm = await DialogUtil.confirm(
                        content:
                            '${AppLocalizations.t('Do you want remove subscript')} ${linkman.name}');
                    if (confirm != true) {
                      return;
                    }
                    linkmanController.changeSubscriptStatus(
                        linkman, LinkmanStatus.N);
                    if (mounted) {
                      DialogUtil.info(
                          content:
                              '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is removed subscript')}');
                    }
                  }),
            );
          } else {
            endSlideActions.add(TileData(
                title: 'Add subscript',
                prefix: Icons.subscriptions,
                onTap: (int index, String title, {String? subtitle}) async {
                  bool? confirm = await DialogUtil.confirm(
                      content:
                          '${AppLocalizations.t('Do you want add subscript')} ${linkman.name}');
                  if (confirm != true) {
                    return;
                  }
                  linkmanController.changeSubscriptStatus(
                      linkman, LinkmanStatus.C);
                  if (mounted) {
                    DialogUtil.info(
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name} ${AppLocalizations.t('is added subscript')}');
                  }
                }));
          }
        }
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    return tiles;
  }

  List<TileData> _buildGroupTileData() {
    var groups = groupController.data;
    List<TileData> tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var groupName = group.name;
        var peerId = group.peerId;
        var groupOwnerName = group.groupOwnerName;
        var groupOwnerPeerId = group.groupOwnerPeerId;
        TileData tile = TileData(
            prefix: group.avatarImage ?? AppImage.mdAppImage,
            title: groupName,
            subtitle: groupOwnerName,
            selected: false,
            onTap: (int index, String title, {String? subtitle}) {
              groupNotifier.value = group;
            },
            routeName: 'group_edit');
        List<TileData> slideActions = [];

        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.group_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              bool? confirm = await DialogUtil.confirm(
                  content:
                      '${AppLocalizations.t('Do you want delete group')} ${group.name}');
              if (confirm != true) {
                return;
              }
              await groupService.removeGroupMember(group, [myself.peerId!]);
              await groupService.removeByGroupId(peerId);
              groupMemberService
                  .delete(where: 'groupId=?', whereArgs: [peerId]);
              await chatSummaryService.removeChatSummary(peerId);
              await chatMessageService.removeByGroup(peerId);
              groupController.delete(index: index);
              if (mounted) {
                DialogUtil.info(
                    content:
                        '${AppLocalizations.t('Group:')} ${group.name} ${AppLocalizations.t('is deleted')}');
              }
            });
        if (groupOwnerPeerId != myself.peerId) {
          slideActions.add(deleteSlideAction);
        }
        TileData dismissSlideAction = TileData(
            title: 'Dismiss',
            prefix: Icons.group_off,
            onTap: (int index, String label, {String? subtitle}) async {
              bool? confirm = await DialogUtil.confirm(
                  content:
                      '${AppLocalizations.t('Do you want dismiss group')} ${group.name}');
              if (confirm != true) {
                return;
              }
              bool success = await groupService.dismissGroup(group);
              if (success) {
                groupMemberService
                    .delete(where: 'groupId=?', whereArgs: [peerId]);
                await chatSummaryService.removeChatSummary(peerId);
                await chatMessageService.removeByGroup(peerId);
                groupController.delete(index: index);
                if (mounted) {
                  DialogUtil.info(
                      content:
                          '${AppLocalizations.t('Group:')} ${group.name} ${AppLocalizations.t('is dismiss')}');
                }
              } else {
                if (mounted) {
                  DialogUtil.error(content: 'Must be group owner');
                }
              }
            });
        if (group.groupOwnerPeerId == myself.peerId) {
          slideActions.add(dismissSlideAction);
        }
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        TileData chatSlideAction = TileData(
            title: 'Chat',
            prefix: Icons.chat,
            onTap: (int index, String label, {String? subtitle}) async {
              ChatSummary? chatSummary =
                  await chatSummaryService.findOneByPeerId(group.peerId);
              chatSummary ??= await chatSummaryService.upsertByGroup(group);
              chatMessageController.chatSummary = chatSummary;
              indexWidgetProvider.push('chat_message');
            });
        endSlideActions.add(chatSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    return tiles;
  }

  List<TileData> _buildConferenceTileData() {
    List<Conference> conferences = conferenceController.data;
    List<TileData> tiles = [];
    if (conferences.isNotEmpty) {
      for (var conference in conferences) {
        var conferenceName = conference.name;
        var conferenceId = conference.conferenceId;
        var conferenceOwnerName = conference.conferenceOwnerName;
        var topic = conference.topic;
        var conferenceOwnerPeerId = conference.conferenceOwnerPeerId;
        String routeName;
        if (conferenceOwnerPeerId == myself.peerId) {
          routeName = 'conference_edit';
        } else {
          routeName = 'conference_show';
        }
        TileData tile = TileData(
            prefix: conference.avatarImage ?? AppImage.mdAppImage,
            title: conferenceName,
            titleTail: conferenceOwnerName,
            subtitle: topic,
            selected: false,
            isThreeLine: false,
            onTap: (int index, String title, {String? subtitle}) {
              conferenceNotifier.value = conference;
            },
            routeName: routeName);
        List<TileData> slideActions = [];

        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              bool? confirm = await DialogUtil.confirm(
                  content:
                      '${AppLocalizations.t('Do you want delete conference')} ${conference.name}');
              if (confirm != true) {
                return;
              }
              await conferenceService.removeByConferenceId(conferenceId);
              groupMemberService
                  .delete(where: 'groupId=?', whereArgs: [conferenceId]);
              await chatSummaryService.removeChatSummary(conferenceId);
              await chatMessageService.removeByGroup(conferenceId);
              conferenceController.delete(index: index);
              if (mounted) {
                DialogUtil.info(
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name} ${AppLocalizations.t('is deleted')}');
              }
            });
        slideActions.add(deleteSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        TileData chatSlideAction = TileData(
            title: 'Chat',
            prefix: Icons.chat,
            onTap: (int index, String label, {String? subtitle}) async {
              ChatSummary? chatSummary = await chatSummaryService
                  .findOneByPeerId(conference.conferenceId);
              chatSummary ??=
                  await chatSummaryService.upsertByConference(conference);
              chatMessageController.chatSummary = chatSummary;
              indexWidgetProvider.push('chat_message');
            });
        endSlideActions.add(chatSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    return tiles;
  }

  _onTapLinkman(int index, String title, {String? subtitle, TileData? group}) {
    linkmanController.setCurrentIndex = index;
  }

  _onTapGroup(int index, String title, {String? subtitle, TileData? group}) {
    groupController.setCurrentIndex = index;
  }

  _onTapConference(int index, String title,
      {String? subtitle, TileData? group}) {
    conferenceController.setCurrentIndex = index;
  }

  Widget _buildLinkmanListView(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      Tab(
        icon: Tooltip(
            message: AppLocalizations.t('Linkman'),
            child: _tabController.index == 0
                ? Icon(
                    Icons.person,
                    color: myself.primary,
                    size: AppIconSize.mdSize,
                  )
                : const Icon(Icons.person, color: Colors.white)),
        text: AppLocalizations.t('Linkman'),
        iconMargin: const EdgeInsets.all(0.0),
      ),
      Tab(
        icon: Tooltip(
            message: AppLocalizations.t('Group'),
            child: _tabController.index == 1
                ? Icon(
                    Icons.group,
                    color: myself.primary,
                    size: AppIconSize.mdSize,
                  )
                : const Icon(Icons.group, color: Colors.white)),
        text: AppLocalizations.t('Group'),
        iconMargin: const EdgeInsets.all(0.0),
      ),
      Tab(
        icon: Tooltip(
            message: AppLocalizations.t('Conference'),
            child: _tabController.index == 2
                ? Icon(
                    Icons.video_chat,
                    color: myself.primary,
                    size: AppIconSize.mdSize,
                  )
                : const Icon(Icons.video_chat, color: Colors.white)),
        text: AppLocalizations.t('Conference'),
        iconMargin: const EdgeInsets.all(0.0),
      ),
    ];
    final tabBar = TabBar(
      tabs: tabs,
      controller: _tabController,
      isScrollable: false,
      indicatorColor: myself.primary,
      //labelColor: Colors.white,
      dividerColor: Colors.white.withOpacity(0),
      padding: const EdgeInsets.all(0.0),
      labelPadding: const EdgeInsets.all(0.0),
      onTap: (int index) {
        if (index == 0) {
          _searchLinkman(_linkmanTextController.text);
        } else if (index == 1) {
          _searchGroup(_groupTextController.text);
        } else if (index == 2) {
          _searchConference(_conferenceTextController.text);
        }
      },
    );
    var linkmanView = Column(children: [
      _buildLinkmanSearchTextField(context),
      Expanded(child: Obx(() {
        List<TileData> tiles = _buildLinkmanTileData();
        return DataListView(
          itemCount: tiles.length,
          itemBuilder: (BuildContext context, int index) {
            return tiles[index];
          },
          onTap: _onTapLinkman,
        );
      }))
    ]);

    var groupView = Column(children: [
      _buildGroupSearchTextField(context),
      Expanded(child: Obx(() {
        List<TileData> tiles = _buildGroupTileData();
        return DataListView(
          itemCount: tiles.length,
          itemBuilder: (BuildContext context, int index) {
            return tiles[index];
          },
          onTap: _onTapGroup,
        );
      }))
    ]);

    var conferenceView = Column(children: [
      _buildConferenceSearchTextField(context),
      Expanded(child: Obx(() {
        List<TileData> tiles = _buildConferenceTileData();
        return DataListView(
          itemCount: tiles.length,
          itemBuilder: (BuildContext context, int index) {
            return tiles[index];
          },
          onTap: _onTapConference,
        );
      }))
    ]);

    final tabBarView = KeepAliveWrapper(
        child: TabBarView(
      controller: _tabController,
      children: [linkmanView, groupView, conferenceView],
    ));

    return Column(
      children: [tabBar, Expanded(child: tabBarView)],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add linkman'),
        onPressed: () {
          linkmanController.setCurrentIndex = -1;
          groupController.setCurrentIndex = -1;
          conferenceController.setCurrentIndex = -1;
          indexWidgetProvider.push('linkman_add');
        },
        icon: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
        ),
      ),
    ];
    if (platformParams.mobile || platformParams.macos || platformParams.web) {
      rightWidgets.add(IconButton(
        tooltip: AppLocalizations.t('Scan qrcode'),
        onPressed: () async {
          await scanQrcode(context);
        },
        icon: const Icon(
          Icons.qr_code,
          color: Colors.white,
        ),
      ));
    }
    return AppBarView(
        title: widget.title,
        rightWidgets: rightWidgets,
        child: _buildLinkmanListView(context));
  }

  Future<void> scanQrcode(BuildContext context) async {
    String? content = await QrcodeUtil.mobileScan(context);
    if (content == null) {
      return;
    }
    var map = JsonUtil.toJson(content);
    PeerClient peerClient = PeerClient.fromJson(map);
    await peerClientService.store(peerClient);
    Linkman linkman = await linkmanService.storeByPeerEntity(peerClient);
    if (linkman.linkmanStatus == LinkmanStatus.F.name) {
      if (mounted) {
        DialogUtil.info(content: '${linkman.name} was friend');
      }
      return;
    }
    if (mounted) {
      bool? confirm = await DialogUtil.confirm(
          content: 'You confirm add ${linkman.name} as friend?');
      if (confirm != null && confirm) {
        await linkmanController.changeLinkmanStatus(linkman, LinkmanStatus.F);
        if (mounted) {
          DialogUtil.info(
              content: 'You add ${linkman.name} as friend successfully');
        }
      }
    }
    if (mounted) {
      String? content = await DialogUtil.showTextFormField(
          content: 'tip', title: AppLocalizations.t('Request add friend'));
      if (content != null) {
        await linkmanService.addFriend(peerClient.peerId, content);
      }
    }
  }
}
