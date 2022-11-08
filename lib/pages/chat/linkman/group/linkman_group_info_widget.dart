import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';


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
class LinkmanGroupInfoWidget extends StatefulWidget with TileDataMixin {
  late final LinkmanGroupEditWidget linkmanGroupEditWidget;

  LinkmanGroupInfoWidget({Key? key}) : super(key: key) {
    linkmanGroupEditWidget = LinkmanGroupEditWidget();
    indexWidgetProvider.define(linkmanGroupEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _LinkmanGroupInfoWidgetState();

  @override
  String get routeName => 'linkman_group_info';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.group);

  @override
  String get title => 'LinkmanGroupInfo';
}

class _LinkmanGroupInfoWidgetState extends State<LinkmanGroupInfoWidget> {
  Group? group;

  @override
  initState() {
    super.initState();
    groupController.addListener(_update);
    group = groupController.current;
  }

  _update() {
    setState(() {});
  }

  _dismissGroup() async {
    if (group == null) {
      return;
    }
    groupService.dismissGroup(group!);
  }

  //显示群基本信息
  Widget _buildGroupInfoWidget(BuildContext context) {
    List<TileData> tileData = [];
    if (group != null) {
      var tile = TileData(
        title: group!.name,
        subtitle: group!.peerId,
        isThreeLine: true,
        prefix: ImageUtil.buildImageWidget(
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
    groupController.removeListener(_update);
    super.dispose();
  }
}
