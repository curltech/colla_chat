import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class QrcodeWidget extends StatefulWidget with TileDataMixin {
  QrcodeWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qrcode';

  @override
  IconData get iconData => Icons.qr_code;

  @override
  String get title => 'Qrcode';

  @override
  State<StatefulWidget> createState() => _QrcodeWidgetState();
}

class _QrcodeWidgetState extends State<QrcodeWidget> {
  GlobalKey? globalKey;
  String? content;
  Widget? qrImage;
  ScreenshotController screenshotController = ScreenshotController();
  final List<ActionData> actionData = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() {
    actionData.clear();
    actionData.add(ActionData(
      label: 'Save to file',
      icon: Icon(Icons.save, color: myself.primary),
    ));
    if (platformParams.mobile) {
      actionData.add(ActionData(
        label: 'Save to image',
        icon: Icon(Icons.image, color: myself.primary),
      ));
    }
    if (platformParams.mobile) {
      actionData.add(ActionData(
        label: 'Share',
        icon: Icon(Icons.share, color: myself.primary),
      ));
    }
    actionData.add(ActionData(
      label: 'Reset qrcode',
      icon: Icon(Icons.lock_reset, color: myself.primary),
    ));
  }

  _onPopAction(BuildContext context, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Save to file':
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        await _saveFile(bytes, myself.peerId!);
        break;
      case 'Save to image':
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        await _saveFile(bytes, myself.peerId!, isFile: false);
        break;
      case 'Share':
        Uint8List bytes = await ImageUtil.clipImageBytes(globalKey!);
        var path = await FileUtil.writeFileAsBytes(bytes, myself.peerId!);
        _share(path);
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

  Future<void> _saveFile(Uint8List bytes, String filename,
      {bool isFile = true}) async {
    if (!isFile) {
      await ImageUtil.saveImageGallery(bytes,
          name: filename, androidExistNotSave: true);
      DialogUtil.info(context, content: 'save to gallery: $filename');
    } else {
      String? dir = await FileUtil.directoryPathPicker();
      if (dir != null) {
        String path = p.join(dir, filename);
        await FileUtil.writeFileAsBytes(bytes, path);
        DialogUtil.info(context, content: 'save to file: $path');
      }
    }
  }

  Future<void> _share(String filename) async {
    final box = context.findRenderObject() as RenderBox?;
    Share.shareXFiles(
      [XFile(filename)],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
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
                        actions: actionData,
                        height: 140,
                        width: 220,
                        iconSize: 20));
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
