import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/tool/xfile_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class QrcodeWidget extends StatefulWidget with TileDataMixin {
  final List<ActionData> actionData = [
    ActionData(
      label: 'Save to file',
      icon: Icon(Icons.save, color: myself.primary),
    ),
    ActionData(
      label: 'Save to image',
      icon: Icon(Icons.image, color: myself.primary),
    ),
    ActionData(
      label: 'Share',
      icon: Icon(Icons.share, color: myself.primary),
    ),
    ActionData(
      label: 'Reset qrcode',
      icon: Icon(Icons.lock_reset, color: myself.primary),
    )
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
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  _onPopAction(BuildContext context, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Save to file':
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        FileUtil.writeFileAsBytes(bytes, myself.peerId!);
        break;
      case 'Save to image':
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        ImageUtil.saveImageGallery(bytes, myself.peerId!);
        //Uint8List? bytes = await screenshotController.capture();
        break;
      case 'Share':
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        var path = await FileUtil.writeFileAsBytes(bytes, myself.peerId!);
        Share.shareXFiles([XFileUtil.open(path)]);
        break;
      case 'Reset qrcode':
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
      Screenshot(
          controller: screenshotController,
          child: Center(
              child: Container(
            key: globalKey,
            alignment: Alignment.center,
            width: 320,
            color: Colors.white,
            padding: const EdgeInsets.all(5.0),
            child: qrImage,
          ))),
      const Spacer(),
      CommonAutoSizeText(
        AppLocalizations.t('Scan qrcode, add linkman'),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 30),
    ];
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () async {
            await DialogUtil.show(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    elevation: 0.0,
                    insetPadding: EdgeInsets.zero,
                    child: DataActionCard(
                        onPressed: (int index, String label, {String? value}) {
                          Navigator.pop(context);
                          _onPopAction(context, index, label, value: value);
                        },
                        crossAxisCount: 2,
                        actions: widget.actionData,
                        height: 140,
                        width: 220,
                        size: 20));
              },
            );
          },
          icon: const Icon(
            Icons.more_horiz,
            color: Colors.white,
          ))
    ];
    return AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: rightWidgets,
      child: Column(children: children),
    );
  }
}
