import 'dart:typed_data';

import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../entity/dht/myself.dart';
import '../../../../tool/util.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/image_widget.dart';
import '../../chat/widget/ui.dart';

class QrcodeWidget extends StatefulWidget with TileDataMixin {
  final List<String> menus = const ['保存文件', '保存图片', '分享', '重置二维码'];

  const QrcodeWidget({Key? key}) : super(key: key);

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
  String peerId = '未登录';
  String name = '未登录';
  QrImage? qrImage;
  GlobalKey? globalKey;
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
          leading: const ImageWidget(
            width: 32.0,
            height: 32.0,
          ),
          title: Text(name),
          subtitle: Text(this.peerId)),
      RepaintBoundary(
          key: globalKey,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: qrImage,
          )),
      Space(height: 2.0),
      const Text('扫一扫上面的二维码图案，加我为好友'),
    ];
    return AppBarView(
      title: '二维码',
      withLeading: widget.withLeading,
      rightActions: widget.menus,
      rightCallBack: _rightCallBack,
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
        ShareUtil.shareFiles([path.path]);
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
