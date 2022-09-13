import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import '../../../../entity/chat/contact.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';

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

  const GroupInfoWidget({Key? key, required this.controller}) : super(key: key);

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
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildGroupInfo(BuildContext context) {
    Group? group = widget.controller.current;
    var listTile = ListTile(
      leading: ImageWidget(
        image: group!.avatar,
        width: 32.0,
        height: 32.0,
      ),
      title: Text(group.name),
      subtitle: Text(group.peerId),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        //indexWidgetProvider.push('personal_info', context: context);
      },
    );
    return listTile;
  }

  Widget _buildGroupButton(BuildContext context) {
    var buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.5)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0)),
      minimumSize: MaterialStateProperty.all(const Size(300, 0)),
      maximumSize: MaterialStateProperty.all(const Size(375.0, 36.0)),
    );
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        height: 15,
      ),
      TextButton(
          style: buttonStyle,
          onPressed: () {
            //Add members
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Add members'),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.group_add)
          ])),
      SizedBox(
        height: 15,
      ),
      TextButton(
          style: buttonStyle,
          onPressed: () {
            //Dismiss group
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Dismiss group'),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.delete_forever)
          ])),
      SizedBox(
        height: 15,
      ),
      TextButton(
          style: buttonStyle,
          onPressed: () {
            //Quit group
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Quit group'),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.exit_to_app)
          ])),
      SizedBox(
        height: 15,
      ),
      TextButton(
          style: buttonStyle,
          onPressed: () {
            //send message
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Chat'),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.chat)
          ])),
      SizedBox(
        height: 15,
      ),
      TextButton(
          style: buttonStyle,
          onPressed: () {
            //send video
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Video chat'),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.video_call)
          ])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var groupInfoCard = Column(
        children: [_buildGroupInfo(context), _buildGroupButton(context)]);
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: groupInfoCard);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
