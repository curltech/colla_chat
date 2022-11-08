import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/qrcode_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/index_widget_provider.dart';
import '../../../../routers/routes.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_group_listview.dart';
import '../../../../widgets/data_bind/data_listtile.dart';

class PersonalInfoWidget extends StatefulWidget with TileDataMixin {
  const PersonalInfoWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PersonalInfoWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'personal_info';

  @override
  Icon get icon => const Icon(Icons.personal_video);

  @override
  String get title => 'Personal Information';
}

class _PersonalInfoWidgetState extends State<PersonalInfoWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    final QrcodeWidget qrcodeWidget = QrcodeWidget();
    indexWidgetProvider.define(qrcodeWidget);
  }

  Widget _buildLogout(BuildContext context) {
    ButtonStyle style =
        WidgetUtil.buildButtonStyle(maximumSize: const Size(140.0, 56.0));

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    return TextButton(
        style: style,
        onPressed: () {
          myselfPeerService.logout();
          indexWidgetProvider.pop(context: context);
          Application.router
              .navigateTo(context, Application.p2pLogin, replace: true);
        },
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(AppLocalizations.t('Logout')),
          const SizedBox(
            width: 5,
          ),
          const Icon(Icons.exit_to_app)
        ]));
  }

  @override
  Widget build(BuildContext context) {
    int id = 0;
    String name;
    var peerId = myself.peerId;
    if (peerId == null) {
      peerId = '未登录';
      name = '未登录';
    } else {
      id = myself.id!;
      name = myself.myselfPeer!.name;
    }
    final List<TileData> personalInfoTileData = [
      TileData(
          title: AppLocalizations.t('Avatar'),
          suffix: myself.avatarImage,
          onTap: (int index, String label, {String? value}) async {
            if (platformParams.windows) {
              List<String> filenames =
                  await FileUtil.pickFiles(type: FileType.image);
              if (filenames.isNotEmpty) {
                List<int> avatar = await FileUtil.readFile(filenames[0]);
                await myselfPeerService.updateAvatar(id, avatar);
                setState(() {});
              }
            }
          }),
      TileData(
        title: AppLocalizations.t('Name'),
        suffix: name,
      ),
      TileData(
        title: AppLocalizations.t('PeerId'),
        subtitle: peerId,
      ),
      TileData(
        title: AppLocalizations.t('Qrcode'),
        routeName: 'qrcode',
      ),
    ];
    var personalInfo = AppBarView(
      title: Text(AppLocalizations.t('Personal Information')),
      withLeading: widget.withLeading,
      child: Column(children: [
        DataListView(tileData: personalInfoTileData),
        const SizedBox(
          height: 15.0,
        ),
        _buildLogout(context)
      ]),
    );

    return personalInfo;
  }
}
