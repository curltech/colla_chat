import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import '../../../../entity/chat/contact.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';
import 'group_edit_widget.dart';

final List<String> groupFields = [
  'name',
  'peerId',
  'givenName',
  'avatar',
  'mobile',
  'email',
  'sourceType',
  'lastConnectTime',
  'createDate',
  'updateDate'
];

//群信息页面
class GroupInfoWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Group> controller;
  late final GroupEditWidget groupEditWidget;

  GroupInfoWidget({Key? key, required this.controller}) : super(key: key) {
    groupEditWidget = GroupEditWidget(controller: controller);
    indexWidgetProvider.define(groupEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _GroupInfoWidgetState();

  @override
  String get routeName => 'group_info';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'GroupInfo';
}

class _GroupInfoWidgetState extends State<GroupInfoWidget> {
  Group? group;

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
    group = widget.controller.current;
  }

  _update() {
    setState(() {});
  }

  _dismissGroup() async {
    if (group == null) {
      return;
    }
    await groupMemberService.delete({
      'groupId': group!.id,
    });
    await groupService.delete({
      'groupId': group!.id,
    });
    await chatMessageService.delete({
      'receiverPeerId': group!.id,
    });
    await chatMessageService.delete({
      'senderPeerId': group!.id,
    });
    await chatSummaryService.delete({
      'peerId': group!.id,
    });
  }

  //显示群基本信息
  Widget _buildGroupInfoWidget(BuildContext context) {
    List<TileData> tileData = [];
    if (group != null) {
      var tile = TileData(
        title: group!.name,
        subtitle: group!.peerId,
        isThreeLine: true,
        prefix: ImageWidget(
          image: group!.avatar,
          width: 32.0,
          height: 32.0,
        ),
        routeName: 'group_edit',
      );
      tileData.add(tile);
    }
    return DataListView(
      tileData: tileData,
    );
  }

  //转向群发界面
  Widget _buildChatMessageWidget(BuildContext context) {
    List<TileData> tileData = [
      TileData(
          title: 'Chat',
          prefix: const Icon(Icons.chat),
          routeName: 'chat_message',
          onTap: (int index, String title) async {
            ChatSummary? chatSummary =
                await chatSummaryService.findOneByPeerId(group!.peerId);
            if (chatSummary != null) {
              chatMessageController.chatSummary = chatSummary;
            }
          }),
    ];
    var listView = DataListView(
      tileData: tileData,
    );
    return listView;
  }

  Widget _buildActionCard(BuildContext context) {
    List<Widget> actionWidgets = [];
    double height = 180;
    final List<ActionData> actionData = [];
    if (group != null) {
      actionData.add(
        ActionData(
            label: 'Dismiss group',
            icon: const Icon(Icons.group_off),
            onTap: (int index, String label, {String? value}) {
              _dismissGroup();
            }),
      );
    }
    actionWidgets.add(DataActionCard(
      actions: actionData,
      height: height,
      crossAxisCount: 3,
    ));
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: Column(children: actionWidgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    var linkmanInfoCard = Column(children: [
      _buildGroupInfoWidget(context),
      _buildChatMessageWidget(context),
      _buildActionCard(context)
    ]);
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: linkmanInfoCard);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
