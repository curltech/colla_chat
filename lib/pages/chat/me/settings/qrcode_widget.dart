import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/tool/share_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class QrcodeWidget extends StatefulWidget with TileDataMixin {
  final List<AppBarPopupMenu> menus = [
    AppBarPopupMenu(
        title: 'Save to file',
        icon: Icon(Icons.save,
            color: appDataProvider.themeData.colorScheme.primary)),
    AppBarPopupMenu(
        title: 'Save to image',
        icon: Icon(Icons.image,
            color: appDataProvider.themeData.colorScheme.primary)),
    AppBarPopupMenu(
        title: 'Share',
        icon: Icon(Icons.share,
            color: appDataProvider.themeData.colorScheme.primary)),
    AppBarPopupMenu(
        title: 'Reset qrcode',
        icon: Icon(Icons.lock_reset,
            color: appDataProvider.themeData.colorScheme.primary))
  ];

  QrcodeWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qrcode';

  @override
  State<StatefulWidget> createState() => _QrcodeWidgetState();

  @override
  Icon get icon => const Icon(Icons.qr_code);

  @override
  String get title => 'Qrcode';
}

class _QrcodeWidgetState extends State<QrcodeWidget> {
  String peerId = AppLocalizations.t('Unknown');
  String name = AppLocalizations.t('None login');
  GlobalKey? globalKey;
  Widget? qrImage;
  String? content;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var peerId = myself.peerId;
    if (peerId != null) {
      this.peerId = peerId;
      name = myself.myselfPeer!.name;
    }
    content = this.peerId;
    qrImage = QrcodeUtil.create(content!);
    globalKey = GlobalKey();
    var children = <Widget>[
      ListTile(
          leading: myself.avatarImage,
          title: Text(name),
          subtitle: Text(this.peerId)),
      SizedBox(
          width: 280,
          key: globalKey,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: qrImage,
          )),
      const Spacer(),
      Text(AppLocalizations.t('Scan qrcode, add linkman')),
    ];
    return AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: widget.withLeading,
      rightPopupMenus: widget.menus,
      child: Column(children: children),
    );
  }

  Future<void> _rightCallBack(int index) async {
    switch (index) {
      case 0:
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        FileUtil.writeFile(bytes, peerId);
        break;
      case 1:
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        ImageUtil.saveImageGallery(bytes, peerId);
        break;
      case 2:
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        var path = await FileUtil.writeFile(bytes, peerId);
        ShareUtil.shareFiles([path]);
        break;
      case 3:
        setState(() {
          qrImage = QrcodeUtil.create(content!);
        });
        break;
      default:
        break;
    }
  }
}
