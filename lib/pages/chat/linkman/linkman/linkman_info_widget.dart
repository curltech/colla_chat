import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import '../../../../entity/chat/contact.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';

//联系人信息页面
class LinkmanInfoWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> controller;

  const LinkmanInfoWidget({Key? key, required this.controller})
      : super(key: key);

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
    var listTile = ListTile(
      leading: ImageWidget(
        image: linkman!.avatar,
        width: 32.0,
        height: 32.0,
      ),
      title: Text(linkman.name),
      subtitle: Text(linkman.peerId),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        //indexWidgetProvider.push('personal_info', context: context);
      },
    );
    return listTile;
  }

  Widget _buildLinkmanButton(BuildContext context) {
    var buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
          Colors.grey.withOpacity(0.5)),
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
            //add friend
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Add friend'),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.person_pin)
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
    var linkmanInfoCard = Column(
        children: [_buildLinkmanInfo(context), _buildLinkmanButton(context)]);
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
