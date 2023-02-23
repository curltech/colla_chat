import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/qrcode_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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
  IconData get iconData => Icons.personal_video;

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
    ButtonStyle style = WidgetUtil.buildButtonStyle(
        maximumSize: const Size(140.0, 56.0), backgroundColor: myself.primary);

    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    return TextButton(
        style: style,
        onPressed: () {
          myselfPeerService.logout();
          indexWidgetProvider.pop(context: context);
          indexWidgetProvider.currentMainIndex = 0;
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
    String name;
    var peerId = myself.peerId;
    if (peerId == null) {
      peerId = '';
      name = '';
    } else {
      name = myself.myselfPeer.name;
    }
    final List<TileData> personalInfoTileData = [
      TileData(
          title: 'Avatar',
          suffix: myself.avatarImage,
          onTap: (
            int index,
            String label, {
            String? subtitle,
          }) async {
            await _pickAvatar(peerId, context);
          }),
      TileData(
        title: 'PeerId',
        subtitle: peerId,
      ),
      TileData(
        title: 'Name',
        suffix: name,
      ),
      TileData(
        title: 'LoginName',
        suffix: myself.myselfPeer.loginName,
      ),
      TileData(
        title: 'Email',
        suffix: myself.myselfPeer.email,
      ),
      TileData(
        title: 'Mobile',
        suffix: myself.myselfPeer.mobile,
      ),
      TileData(
        title: 'Qrcode',
        routeName: 'qrcode',
      ),
    ];
    var personalInfo = AppBarView(
      title: widget.title,
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

  Future<void> _pickAvatar(String? peerId, BuildContext context) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.image);
      if (xfiles.isNotEmpty) {
        List<int> avatar = await xfiles[0].readAsBytes();
        await myselfPeerService.updateAvatar(peerId!, avatar);
        setState(() {});
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        List<int>? avatar = await assets[0].originBytes;
        if (avatar != null) {
          await myselfPeerService.updateAvatar(peerId!, avatar);
          setState(() {});
        }
      }
    }
  }
}
