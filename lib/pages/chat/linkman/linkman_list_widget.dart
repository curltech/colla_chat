import 'package:barcode_scan2/model/model.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_view.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_add_widget.dart';
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
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

final DataListController<Linkman> linkmanController =
    DataListController<Linkman>();
final DataListController<Group> groupController = DataListController<Group>();
final DataListController<Conference> conferenceController =
    DataListController<Conference>();

///联系人和群的查询界面
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  final LinkmanAddWidget linkmanAddWidget = LinkmanAddWidget();
  final LinkmanEditWidget linkmanEditWidget = LinkmanEditWidget();
  final ConferenceShowView conferenceShowView = ConferenceShowView();
  late final List<TileData> linkmanTileData;

  LinkmanListWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(linkmanEditWidget);
    indexWidgetProvider.define(linkmanAddWidget);
    indexWidgetProvider.define(conferenceShowView);
    List<TileDataMixin> mixins = [
      linkmanEditWidget,
      linkmanAddWidget,
      conferenceShowView,
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
}

class _LinkmanListWidgetState extends State<LinkmanListWidget>
    with TickerProviderStateMixin {
  final TextEditingController _linkmanTextController = TextEditingController();
  final TextEditingController _groupTextController = TextEditingController();
  final TextEditingController _conferenceTextController =
      TextEditingController();
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
    linkmanController.addListener(_updateLinkman);
    groupController.addListener(_updateGroup);
    conferenceController.addListener(_updateConference);
    _searchLinkman(_linkmanTextController.text);
    _searchGroup(_groupTextController.text);
    _searchConference(_conferenceTextController.text);
  }

  _updateCurrentTab() {
    _currentTab.value = _tabController.index;
  }

  _updateLinkman() {
    _buildLinkmanTileData();
  }

  _updateGroup() {
    _buildGroupTileData();
  }

  _updateConference() {
    _buildConferenceTileData();
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
        child: CommonAutoSizeTextFormField(
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
        child: CommonAutoSizeTextFormField(
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
        child: CommonAutoSizeTextFormField(
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

  _changeLinkmanStatus(Linkman linkman, LinkmanStatus status) async {
    int id = linkman.id!;
    await linkmanService.update({'id': id, 'linkmanStatus': status.name});
  }

  _changeSubscriptStatus(Linkman linkman, LinkmanStatus status) async {
    int id = linkman.id!;
    await linkmanService.update({'id': id, 'subscriptStatus': status.name});
  }

  //将linkman和group数据转换从列表显示数据
  _buildLinkmanTileData() {
    var linkmen = linkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var name = linkman.name;
        var peerId = linkman.peerId;
        String? linkmanStatus = linkman.linkmanStatus ?? '';
        linkmanStatus = AppLocalizations.t(linkmanStatus);
        if (peerId == myself.peerId) {
          linkmanStatus = AppLocalizations.t('myself');
        }
        Widget? prefix = linkman.avatarImage;
        String routeName = 'linkman_edit';
        if (linkmanStatus == LinkmanStatus.chatGPT.name) {
          // prefix = prefix ??
          //     ImageUtil.buildImageWidget(
          //         image: 'assets/images/openai.png',
          //         width: AppIconSize.lgSize,
          //         height: AppIconSize.lgSize);
          routeName = 'chat_gpt_add';
        }
        prefix = prefix ?? AppImage.mdAppImage;
        TileData tile = TileData(
            prefix: prefix,
            title: name,
            subtitle: linkmanStatus,
            selected: false,
            routeName: routeName);
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.person_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              linkmanController.currentIndex = index;
              await linkmanService.removeByPeerId(linkman.peerId);
              await chatSummaryService.removeChatSummary(linkman.peerId);
              await chatMessageService.removeByLinkman(linkman.peerId);
              linkmanController.delete();
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Linkman:')} ${linkman.name}${AppLocalizations.t(' is deleted')}');
              }
            });
        slideActions.add(deleteSlideAction);
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
        if (linkman.status == LinkmanStatus.blacklist.name) {
          endSlideActions.add(
            TileData(
                title: 'Remove blacklist',
                prefix: Icons.person_outlined,
                onTap: (int index, String title, {String? subtitle}) async {
                  await _changeLinkmanStatus(linkman, LinkmanStatus.stranger);
                  if (mounted) {
                    DialogUtil.info(context,
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name}${AppLocalizations.t(' is removed blacklist')}');
                  }
                }),
          );
        } else {
          endSlideActions.add(TileData(
              title: 'Add blacklist',
              prefix: Icons.person_off,
              onTap: (int index, String title, {String? subtitle}) async {
                await _changeLinkmanStatus(linkman, LinkmanStatus.blacklist);
                if (mounted) {
                  DialogUtil.info(context,
                      content:
                          '${AppLocalizations.t('Linkman:')} ${linkman.name}${AppLocalizations.t(' is added blacklist')}');
                }
              }));
        }
        if (linkman.status == LinkmanStatus.blacklist.name) {
          endSlideActions.add(
            TileData(
                title: 'Remove subscript',
                prefix: Icons.unsubscribe,
                onTap: (int index, String title, {String? subtitle}) async {
                  await _changeSubscriptStatus(linkman, LinkmanStatus.none);
                  if (mounted) {
                    DialogUtil.info(context,
                        content:
                            '${AppLocalizations.t('Linkman:')} ${linkman.name}${AppLocalizations.t(' is removed subscript')}');
                  }
                }),
          );
        } else {
          endSlideActions.add(TileData(
              title: 'Add subscript',
              prefix: Icons.subscriptions,
              onTap: (int index, String title, {String? subtitle}) async {
                await _changeSubscriptStatus(linkman, LinkmanStatus.subscript);
                if (mounted) {
                  DialogUtil.info(context,
                      content:
                          '${AppLocalizations.t('Linkman:')} ${linkman.name}${AppLocalizations.t(' is added subscript')}');
                }
              }));
        }
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    _linkmanTileData.value = tiles;
  }

  _buildGroupTileData() {
    var groups = groupController.data;
    List<TileData> tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var groupName = group.name;
        var peerId = group.peerId;
        var groupOwnerName = group.groupOwnerName;
        TileData tile = TileData(
            prefix: group.avatarImage ?? AppImage.mdAppImage,
            title: groupName,
            subtitle: groupOwnerName,
            selected: false,
            routeName: 'linkman_add_group');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.group_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              groupController.currentIndex = index;
              await groupService.removeByGroupPeerId(peerId);
              await groupMemberService.removeByGroupPeerId(peerId);
              await chatSummaryService.removeChatSummary(peerId);
              await chatMessageService.removeByGroup(peerId);
              groupController.delete();
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Group:')} ${group.name}${AppLocalizations.t(' is deleted')}');
              }
            });
        slideActions.add(deleteSlideAction);
        TileData dismissSlideAction = TileData(
            title: 'Dismiss',
            prefix: Icons.group_off,
            onTap: (int index, String label, {String? subtitle}) async {
              if (group.ownerPeerId == myself.peerId) {
                await groupService.dismissGroup(group);
                if (mounted) {
                  DialogUtil.info(context,
                      content:
                          '${AppLocalizations.t('Group:')} ${group.name}${AppLocalizations.t(' is dismiss')}');
                }
              } else {
                DialogUtil.error(context, content: 'Must be group owner');
              }
            });
        slideActions.add(dismissSlideAction);
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
    _groupTileData.value = tiles;
  }

  _buildConferenceTileData() {
    var conferences = conferenceController.data;
    List<TileData> tiles = [];
    if (conferences.isNotEmpty) {
      for (var conference in conferences) {
        var conferenceName = conference.name;
        var conferenceId = conference.conferenceId;
        var conferenceOwnerName = conference.conferenceOwnerName;
        var topic = conference.topic;
        TileData tile = TileData(
            prefix: conference.avatarImage ?? AppImage.mdAppImage,
            title: conferenceName,
            titleTail: conferenceOwnerName,
            subtitle: topic,
            selected: false,
            isThreeLine: false,
            routeName: 'conference_add');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              conferenceController.currentIndex = index;
              await conferenceService.removeByConferenceId(conferenceId);
              await groupMemberService.removeByGroupPeerId(conferenceId);
              await chatSummaryService.removeChatSummary(conferenceId);
              await chatMessageService.removeByGroup(conferenceId);
              conferenceController.delete();
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is deleted')}');
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
    _conferenceTileData.value = tiles;
  }

  _onTapLinkman(int index, String title, {String? subtitle, TileData? group}) {
    linkmanController.currentIndex = index;
  }

  _onTapGroup(int index, String title, {String? subtitle, TileData? group}) {
    groupController.currentIndex = index;
  }

  _onTapConference(int index, String title,
      {String? subtitle, TileData? group}) {
    conferenceController.currentIndex = index;
  }

  Widget _buildLinkmanListView(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Icon(Icons.person_outline,
                  color: value == 0 ? myself.primary : Colors.white),
              //text: AppLocalizations.t('Linkman'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Icon(Icons.group_outlined,
                  color: value == 1 ? myself.primary : Colors.white),
              //text: AppLocalizations.t('Group'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _currentTab,
          builder: (context, value, child) {
            return Tab(
              icon: Icon(Icons.meeting_room_outlined,
                  color: value == 2 ? myself.primary : Colors.white),
              //text: AppLocalizations.t('Group'),
              iconMargin: const EdgeInsets.all(0.0),
            );
          }),
    ];
    final tabBar = TabBar(
      tabs: tabs,
      controller: _tabController,
      isScrollable: false,
      indicatorColor: myself.primary.withOpacity(AppOpacity.xlOpacity),
      //labelColor: Colors.white,
      dividerColor: Colors.white.withOpacity(AppOpacity.xlOpacity),
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
      Expanded(
          child: ValueListenableBuilder(
              valueListenable: _linkmanTileData,
              builder: (context, value, child) {
                return DataListView(
                  tileData: value,
                  onTap: _onTapLinkman,
                );
              }))
    ]);

    var groupView = Column(children: [
      _buildGroupSearchTextField(context),
      Expanded(
          child: ValueListenableBuilder(
              valueListenable: _groupTileData,
              builder: (context, value, child) {
                return DataListView(
                  tileData: value,
                  onTap: _onTapGroup,
                );
              }))
    ]);

    var conferenceView = Column(children: [
      _buildConferenceSearchTextField(context),
      Expanded(
          child: ValueListenableBuilder(
              valueListenable: _conferenceTileData,
              builder: (context, value, child) {
                return DataListView(
                  tileData: value,
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
        onPressed: () {
          linkmanController.currentIndex = -1;
          groupController.currentIndex = -1;
          conferenceController.currentIndex = -1;
          indexWidgetProvider.push('linkman_add');
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        onPressed: () async {
          ScanResult scanResult = await QrcodeUtil.scan();
          String content = scanResult.rawContent;
          var map = JsonUtil.toJson(content);
          PeerClient peerClient = PeerClient.fromJson(map);
          await peerClientService.store(peerClient);
          await linkmanService.storeByPeerClient(peerClient);
        },
        icon: const Icon(Icons.qr_code),
      )
    ];

    return AppBarView(
        title: widget.title,
        //rightWidgets: rightWidgets,
        rightWidgets: rightWidgets,
        child: _buildLinkmanListView(context));
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateCurrentTab);
    _tabController.dispose();
    linkmanController.removeListener(_updateLinkman);
    groupController.removeListener(_updateGroup);
    groupController.removeListener(_updateConference);
    super.dispose();
  }
}
