import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/tool/xfile_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class QrcodeWidget extends StatefulWidget with TileDataMixin {
  final List<AppBarPopupMenu> menus = [
    AppBarPopupMenu(
        title: 'Save to file', icon: Icon(Icons.save, color: myself.primary)),
    AppBarPopupMenu(
        title: 'Save to image', icon: Icon(Icons.image, color: myself.primary)),
    AppBarPopupMenu(
        title: 'Share', icon: Icon(Icons.share, color: myself.primary)),
    AppBarPopupMenu(
        title: 'Reset qrcode',
        icon: Icon(Icons.lock_reset, color: myself.primary))
  ];

  QrcodeWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qrcode';

  @override
  State<StatefulWidget> createState() => _QrcodeWidgetState();

  @override
  IconData get iconData => Icons.qr_code;

  @override
  String get title => 'Qrcode';
}

class _QrcodeWidgetState extends State<QrcodeWidget> {
  GlobalKey? globalKey;
  String? content;
  Widget? qrImage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _rightCallBack(int index) async {
    switch (index) {
      case 0:
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        FileUtil.writeFileAsBytes(bytes, myself.peerId!);
        break;
      case 1:
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        ImageUtil.saveImageGallery(bytes, myself.peerId!);
        break;
      case 2:
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        var path = await FileUtil.writeFileAsBytes(bytes, myself.peerId!);
        Share.shareXFiles([XFileUtil.open(path)]);
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

  @override
  Widget build(BuildContext context) {
    var peerId = myself.peerId ?? '';
    var name = myself.myselfPeer.name ?? '';
    content = JsonUtil.toJsonString({
      'peerId': myself.myselfPeer.peerId,
      'name': myself.myselfPeer.name,
      'clientId': myself.myselfPeer.clientId,
      'mobile': myself.myselfPeer.mobile,
      'email': myself.myselfPeer.email,
      'peerPublicKey': myself.myselfPeer.peerPublicKey,
      'publicKey': myself.myselfPeer.publicKey,
    });
    qrImage = QrcodeUtil.create(content!);
    globalKey = GlobalKey();
    var children = <Widget>[
      ListTile(
          leading: myself.avatarImage,
          title: CommonAutoSizeText(name),
          subtitle: CommonAutoSizeText(peerId)),
      const SizedBox(
        height: 40.0,
      ),
      Center(
          child: Container(
        key: globalKey,
        alignment: Alignment.center,
        width: 300,
        color: Colors.white,
        padding: const EdgeInsets.all(5.0),
        child: qrImage,
      )),
      const Spacer(),
      CommonAutoSizeText(AppLocalizations.t('Scan qrcode, add linkman')),
      const SizedBox(height: 30),
    ];
    return AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      //rightPopupMenus: widget.menus,
      child: Column(children: children),
    );
  }
}
