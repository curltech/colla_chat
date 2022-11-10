import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_edit_widget.dart';
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

//联系人信息页面
class LinkmanInfoWidget extends StatefulWidget with TileDataMixin {
  late final LinkmanEditWidget linkmanEditWidget;

  LinkmanInfoWidget({Key? key}) : super(key: key) {
    linkmanEditWidget = LinkmanEditWidget();
    indexWidgetProvider.define(linkmanEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _LinkmanInfoWidgetState();

  @override
  String get routeName => 'linkman_info';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Linkman Information';
}

class _LinkmanInfoWidgetState extends State<LinkmanInfoWidget> {
  Linkman? linkman;

  @override
  initState() {
    super.initState();
    linkmanController.addListener(_update);
    linkman = linkmanController.current;
  }

  _update() {
    setState(() {});
  }

  Widget _buildLinkmanInfoWidget(BuildContext context) {
    List<TileData> tileData = [];
    if (linkman != null) {
      var tile = TileData(
        title: linkman!.name,
        subtitle: linkman!.peerId,
        isThreeLine: true,
        prefix: ImageUtil.buildImageWidget(
          image: linkman!.avatar,
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

  Widget _buildChatMessageWidget(BuildContext context) {
    List<TileData> tileData = [];
    var tile = TileData(
        title: AppLocalizations.t('Chat'),
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

  _addFriend({String? tip}) async {
    await _changeStatus(LinkmanStatus.friend);
    // 加好友会发送自己的信息，回执将收到对方的信息
    await linkmanService.addFriend(linkman!, tip!);
  }

  _changeStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'status': status.name});
    linkman = await linkmanService.findOne(where: 'id=?', whereArgs: [id]);
    linkmanController.current = linkman;
  }

  _changeSubscriptStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'subscriptStatus': status.name});
    linkman = await linkmanService.findOne(where: 'id=?', whereArgs: [id]);
    linkmanController.current = linkman;
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
                  _addFriend(tip: controller.text);
                },
                icon: const Icon(Icons.person_add),
              ),
            )));

    return addFriendTextField;
  }

  Widget _buildActionCard(BuildContext context) {
    List<Widget> actionWidgets = [];
    double height = 180;
    final List<ActionData> actionData = [];
    if (linkman != null) {
      if (linkman!.status == LinkmanStatus.friend.name) {
        actionData.add(
          ActionData(
              label: AppLocalizations.t('Remove friend'),
              icon: const Icon(Icons.person_remove),
              onTap: (int index, String label, {String? value}) {
                _changeStatus(LinkmanStatus.none);
              }),
        );
      } else {
        actionWidgets.add(_buildAddFriendTextField(context));
      }
      if (linkman!.status == LinkmanStatus.blacklist.name) {
        actionData.add(
          ActionData(
              label: AppLocalizations.t('Remove blacklist'),
              icon: const Icon(Icons.person_outlined),
              onTap: (int index, String label, {String? value}) {
                _changeStatus(LinkmanStatus.none);
              }),
        );
      } else {
        actionData.add(ActionData(
            label: AppLocalizations.t('Add blacklist'),
            icon: const Icon(Icons.person_off),
            onTap: (int index, String label, {String? value}) {
              _changeStatus(LinkmanStatus.blacklist);
            }));
      }
      if (linkman!.status == LinkmanStatus.blacklist.name) {
        actionData.add(
          ActionData(
              label: AppLocalizations.t('Remove subscript'),
              icon: const Icon(Icons.unsubscribe),
              onTap: (int index, String label, {String? value}) {
                _changeSubscriptStatus(LinkmanStatus.none);
              }),
        );
      } else {
        actionData.add(ActionData(
            label: AppLocalizations.t('Add subscript'),
            icon: const Icon(Icons.subscriptions),
            onTap: (int index, String label, {String? value}) {
              _changeSubscriptStatus(LinkmanStatus.subscript);
            }));
      }
    }
    actionWidgets.add(DataActionCard(
      actions: actionData,
      height: height,
      crossAxisCount: 4,
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
      _buildLinkmanInfoWidget(context),
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
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
