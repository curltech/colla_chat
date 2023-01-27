import 'package:barcode_scan2/model/model.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_edit_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

final DataListController<Linkman> linkmanController =
    DataListController<Linkman>();
final DataListController<Group> groupController = DataListController<Group>();

///联系人和群的查询界面
class LinkmanListWidget extends StatefulWidget with TileDataMixin {
  //linkman和group的数据显示列表
  final GroupDataListController groupDataListController =
      GroupDataListController();
  final LinkmanEditWidget linkmanEditWidget = LinkmanEditWidget();
  final LinkmanAddWidget linkmanAddWidget = LinkmanAddWidget();
  final GroupAddWidget groupAddWidget = GroupAddWidget();

  LinkmanListWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(linkmanEditWidget);
    indexWidgetProvider.define(linkmanAddWidget);
    indexWidgetProvider.define(groupAddWidget);
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

class _LinkmanListWidgetState extends State<LinkmanListWidget> {
  TextEditingController controller = TextEditingController();

  @override
  initState() {
    super.initState();
    linkmanController.addListener(_update);
    groupController.addListener(_update);
    widget.groupDataListController.addListener(_update);
    _buildGroupDataListController();
    _search(controller.text);
  }

  _update() {
    setState(() {});
  }

  _search(String key) async {
    List<Linkman> linkmen = await linkmanService.search(key);
    List<Linkman> ls = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        Linkman? l = await linkmanService.findCachedOneByPeerId(linkman.peerId);
        if (l != null) {
          ls.add(l);
        }
      }
    }
    linkmanController.replaceAll(ls);
    List<Group> groups = await groupService.search(key);
    List<Group> gs = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        Group? g = await groupService.findCachedOneByPeerId(group.peerId);
        if (g != null) {
          gs.add(g);
        }
      }
    }
    groupController.replaceAll(gs);
  }

  _buildSearchTextField(BuildContext context) {
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
              filled: true,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              //labelText: AppLocalizations.t('Search'),
              suffixIcon: IconButton(
                onPressed: () {
                  _search(controller.text);
                },
                icon: Icon(
                  Icons.search,
                  color: myself.primary,
                ),
              ),
            )));

    return searchTextField;
  }

  _changeStatus(Linkman linkman, LinkmanStatus status) async {
    int id = linkman.id!;
    await linkmanService.update({'id': id, 'status': status.name});
  }

  _changeSubscriptStatus(Linkman linkman, LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'subscriptStatus': status.name});
  }

  //将linkman和group数据转换从列表显示数据
  _buildGroupDataListController() {
    widget.groupDataListController.controllers.clear();
    var linkmen = linkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name;
        var subtitle = linkman.peerId;
        TileData tile = TileData(
            prefix: linkman.avatarImage,
            title: title,
            subtitle: subtitle,
            selected: false,
            routeName: 'linkman_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.person_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              linkmanController.currentIndex = index;
              await linkmanService.delete(entity: linkman);
              await chatSummaryService.removeChatSummary(subtitle!);
              await chatMessageService.removeByLinkman(subtitle);
              linkmanController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData chatSlideAction = TileData(
            title: 'Chat',
            prefix: Icons.chat,
            onTap: (int index, String label, {String? subtitle}) async {
              ChatSummary? chatSummary =
                  await chatSummaryService.findOneByPeerId(linkman.peerId);
              if (chatSummary != null) {
                chatMessageController.chatSummary = chatSummary;
              }
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
                onTap: (int index, String title, {String? subtitle}) {
                  _changeStatus(linkman, LinkmanStatus.stranger);
                }),
          );
        } else {
          endSlideActions.add(TileData(
              title: 'Add blacklist',
              prefix: Icons.person_off,
              onTap: (int index, String title, {String? subtitle}) {
                _changeStatus(linkman, LinkmanStatus.blacklist);
              }));
        }
        if (linkman.status == LinkmanStatus.blacklist.name) {
          endSlideActions.add(
            TileData(
                title: 'Remove subscript',
                prefix: Icons.unsubscribe,
                onTap: (int index, String title, {String? subtitle}) {
                  _changeSubscriptStatus(linkman, LinkmanStatus.stranger);
                }),
          );
        } else {
          endSlideActions.add(TileData(
              title: 'Add subscript',
              prefix: Icons.subscriptions,
              onTap: (int index, String title, {String? subtitle}) {
                _changeSubscriptStatus(linkman, LinkmanStatus.subscript);
              }));
        }
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    var keyTile = TileData(title: 'Linkman');
    widget.groupDataListController.add(keyTile, tiles);

    var groups = groupController.data;
    tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var title = group.name;
        var subtitle = group.peerId;
        TileData tile = TileData(
            prefix: group.avatarImage,
            title: title,
            subtitle: subtitle,
            selected: false,
            routeName: 'linkman_group_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.group_remove,
            onTap: (int index, String label, {String? subtitle}) async {
              groupController.currentIndex = index;
              await groupService.delete(entity: group);
              await chatSummaryService.removeChatSummary(subtitle!);
              await chatMessageService.removeByGroup(subtitle);
              groupController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData dismissSlideAction = TileData(
            title: 'Dismiss',
            prefix: Icons.group_off,
            onTap: (int index, String label, {String? subtitle}) async {
              groupService.dismissGroup(group);
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
              if (chatSummary != null) {
                chatMessageController.chatSummary = chatSummary;
              }
              indexWidgetProvider.push('chat_message');
            });
        endSlideActions.add(chatSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    keyTile = TileData(title: 'Group');
    widget.groupDataListController.add(keyTile, tiles);
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    if (group != null) {
      if (group.title == 'Linkman') {
        linkmanController.currentIndex = index;
      }
      if (group.title == 'Group') {
        groupController.currentIndex = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var rightWidgets = [
      IconButton(
          onPressed: () {
            linkmanController.currentIndex = -1;
            indexWidgetProvider.push('linkman_add');
          },
          icon: const Icon(Icons.person_add_alt, color: Colors.white),
          tooltip: AppLocalizations.t('Add linkman')),
      IconButton(
          onPressed: () {
            groupController.currentIndex = -1;
            indexWidgetProvider.push('group_add');
          },
          icon: const Icon(Icons.group_add, color: Colors.white),
          tooltip: AppLocalizations.t('Add group')),
      IconButton(
          onPressed: () async {
            ScanResult scanResult = await QrcodeUtil.scan();
            String content = scanResult.rawContent;
            var map = JsonUtil.toJson(content);
            PeerClient peerClient = PeerClient.fromJson(map);
            await peerClientService.store(peerClient);
            await linkmanService.storeByPeerClient(peerClient);
          },
          icon: const Icon(Icons.qr_code, color: Colors.white),
          tooltip: AppLocalizations.t('Qrcode scan')),
    ];
    _buildGroupDataListController();
    var groupDataListView = Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: GroupDataListView(
          onTap: _onTap,
          controller: widget.groupDataListController,
        ));
    return AppBarView(
        title: widget.title,
        rightWidgets: rightWidgets,
        child: Column(children: [
          _buildSearchTextField(context),
          Expanded(child: groupDataListView)
        ]));
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    groupController.removeListener(_update);
    widget.groupDataListController.removeListener(_update);
    super.dispose();
  }
}
