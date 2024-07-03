import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/myself_qrcode_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonalInfoWidget extends StatefulWidget with TileDataMixin {
  const PersonalInfoWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PersonalInfoWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'personal_info';

  @override
  IconData get iconData => Icons.personal_injury_outlined;

  @override
  String get title => 'Personal Information';
}

class _PersonalInfoWidgetState extends State<PersonalInfoWidget>
    with SingleTickerProviderStateMixin {
  List<TileData> personalInfoTileData = [];

  @override
  void initState() {
    super.initState();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    final MyselfQrcodeWidget qrcodeWidget = MyselfQrcodeWidget();
    indexWidgetProvider.define(qrcodeWidget);
  }

  _init() {
    personalInfoTileData = [
      TileData(
          title: 'Avatar',
          suffix: myself.avatarImage,
          onTap: (
            int index,
            String label, {
            String? subtitle,
          }) async {
            await _pickAvatar(
              context,
              myself.peerId!,
            );
          }),
      TileData(
        title: 'Id',
        subtitle: myself.myselfPeer.id?.toString(),
      ),
      TileData(
        title: 'PeerId',
        subtitle: myself.peerId,
      ),
      TileData(
          title: 'Name',
          suffix: myself.myselfPeer.name,
          onTap: (
            int index,
            String label, {
            String? subtitle,
          }) async {
            String? name = await DialogUtil.showTextFormField(context,
                title: 'Update name',
                content: 'Name',
                tip: myself.myselfPeer.name);
            if (name != null) {
              myself.myselfPeer.name = name;
              myselfPeerService.update({'name': name},
                  where: 'id=?', whereArgs: [myself.myselfPeer.id!]);
              setState(() {});
            }
          }),
      TileData(
        title: 'LoginName',
        suffix: myself.myselfPeer.loginName,
      ),
      TileData(
          title: 'Email',
          suffix: myself.myselfPeer.email,
          onTap: (
            int index,
            String label, {
            String? subtitle,
          }) async {
            String? email = await DialogUtil.showTextFormField(context,
                title: 'Update email',
                content: 'Email',
                tip: myself.myselfPeer.email);
            if (email != null) {
              myself.myselfPeer.email = email;
              myselfPeerService.update({'email': email},
                  where: 'id=?', whereArgs: [myself.myselfPeer.id!]);
              setState(() {});
            }
          }),
      TileData(
          title: 'Mobile',
          suffix: myself.myselfPeer.mobile,
          onTap: (
            int index,
            String label, {
            String? subtitle,
          }) async {
            String? mobile = await DialogUtil.showTextFormField(context,
                title: 'Update mobile',
                content: 'Mobile',
                tip: myself.myselfPeer.mobile);
            if (mobile != null) {
              myself.myselfPeer.mobile = mobile;
              myselfPeerService.update({'mobile': mobile},
                  where: 'id=?', whereArgs: [myself.myselfPeer.id!]);
              setState(() {});
            }
          }),
      TileData(
        title: 'StartDate',
        suffix: myself.myselfPeer.startDate,
      ),
      TileData(
        title: 'Myself Qrcode',
        routeName: 'myself_qrcode',
      ),
    ];
  }

  Widget _buildLogout(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle(
        maximumSize: const Size(140.0, 56.0), backgroundColor: myself.primary);

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    return TextButton.icon(
      style: style,
      icon: const Icon(Icons.exit_to_app),
      label: CommonAutoSizeText(AppLocalizations.t('Logout')),
      onPressed: () {
        myselfPeerService.logout();
        indexWidgetProvider.pop(context: context);
        indexWidgetProvider.currentMainIndex = 0;
        Application.router
            .navigateTo(context, Application.p2pLogin, replace: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _init();
    var personalInfo = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      child: Column(children: [
        DataListView(
          itemCount: personalInfoTileData.length,
          itemBuilder: (BuildContext context, int index) {
            return personalInfoTileData[index];
          },
        ),
        const SizedBox(
          height: 15.0,
        ),
        _buildLogout(context)
      ]),
    );

    return personalInfo;
  }

  Future<void> _pickAvatar(
    BuildContext context,
    String peerId,
  ) async {
    Uint8List? avatar = await ImageUtil.pickAvatar(context);
    if (avatar == null) {
      bool? confirm = await DialogUtil.confirm(context,
          content: 'Do you want delete avatar?');
      if (confirm == null || !confirm) {
        return;
      }
    }
    await myselfPeerService.updateAvatar(peerId, avatar);
    setState(() {});
  }
}
