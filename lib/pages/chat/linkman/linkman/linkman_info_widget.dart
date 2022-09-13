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
import 'linkman_edit_widget.dart';

//联系人信息页面
class LinkmanInfoWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> controller;
  late final LinkmanEditWidget linkmanEditWidget;

  LinkmanInfoWidget({Key? key, required this.controller}) : super(key: key) {
    linkmanEditWidget = LinkmanEditWidget(controller: controller);
    indexWidgetProvider.define(linkmanEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _LinkmanInfoWidgetState();

  @override
  String get routeName => 'linkman_info';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'Linkman Info';
}

class _LinkmanInfoWidgetState extends State<LinkmanInfoWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildLinkmanInfo(BuildContext context) {
    Linkman? linkman = widget.controller.current;
    List<TileData> tileData = [];
    if (linkman != null) {
      var tile = TileData(
        title: linkman.name,
        subtitle: linkman.peerId,
        isThreeLine: true,
        prefix: ImageWidget(
          image: linkman.avatar,
          width: 32.0,
          height: 32.0,
        ),
        routeName: 'linkman_edit',
      );
      tileData.add(tile);
    }
    return DataListView(
      tileData: tileData,
    );
  }

  Widget _buildListTile(BuildContext context) {
    Linkman? linkman = widget.controller.current;
    List<TileData> tileData = [];
    var tile = TileData(
        title: 'Chat',
        prefix: const Icon(Icons.chat),
        routeName: 'chat_message',
        onTap: (int index, String title) async {
          ChatSummary? chatSummary =
              await chatSummaryService.findOneByPeerId(linkman!.peerId);
          if (chatSummary != null) {
            chatMessageController.chatSummary = chatSummary;
          }
        });
    tileData.add(tile);
    return DataListView(
      tileData: tileData,
    );
  }

  _addFriend(Linkman linkman, {String? tip}) async {
    await linkmanService
        .update({'id': linkman.id, 'status': LinkmanStatus.friend.name});
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        linkman.peerId,
        subMessageType: ChatSubMessageType.addLinkman,
        title: tip);
    await chatMessageService.send(chatMessage);
  }

  Widget _buildAddFriendTextField(BuildContext context) {
    var controller = TextEditingController();
    var addFriendTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.black.withOpacity(0.1),
              filled: true,
              border: InputBorder.none,
              labelText: AppLocalizations.t('Add Friend'),
              suffixIcon: IconButton(
                onPressed: () {
                  _addFriend(widget.controller.current!, tip: controller.text);
                },
                icon: const Icon(Icons.person_add),
              ),
            )));

    return addFriendTextField;
  }

  Widget _buildActionCard(BuildContext context) {
    Linkman? linkman = widget.controller.current;
    List<Widget> actionWidgets = [];
    double height = 180;
    final List<ActionData> actionData = [];
    if (linkman != null) {
      if (linkman.status == LinkmanStatus.friend.name) {
        actionData.add(
          ActionData(
              label: 'Remove friend', icon: const Icon(Icons.person_remove)),
        );
      } else {
        actionWidgets.add(_buildAddFriendTextField(context));
      }
      if (linkman.status == LinkmanStatus.blacklist.name) {
        actionData.add(
          ActionData(
              label: 'Remove blacklist',
              icon: const Icon(Icons.person_outlined)),
        );
      } else {
        actionData.add(ActionData(
            label: 'Add blacklist', icon: const Icon(Icons.person_off)));
      }
      if (linkman.status == LinkmanStatus.blacklist.name) {
        actionData.add(
          ActionData(
              label: 'Remove subscript', icon: const Icon(Icons.unsubscribe)),
        );
      } else {
        actionData.add(ActionData(
            label: 'Add subscript', icon: const Icon(Icons.subscriptions)));
      }
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
      _buildLinkmanInfo(context),
      _buildListTile(context),
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
