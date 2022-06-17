import 'package:flutter/material.dart';

import '../../../../entity/dht/myself.dart';
import '../../../../tool/util.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/image_widget.dart';
import '../../chat/widget/ui.dart';

class QrCodeWidget extends StatelessWidget {
  final Function? backCallBack;
  final String content;

  List<String> menus = ['换个样式', '保存到手机', '扫描二维码', '重置二维码'];

  QrCodeWidget({Key? key, required this.content, this.backCallBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      ListTile(
          leading: const ImageWidget(
            width: 32.0,
            height: 32.0,
          ),
          title: Text(myself.myselfPeer!.name!),
          subtitle: Text(myself.peerId!)),
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: QrcodeUtil.create(content),
      ),
      Space(height: 2.0),
      const Text('扫一扫上面的二维码图案，加我微信'),
    ];
    return AppBarView(
      title: '二维码',
      backCallBack: backCallBack,
      rightActions: menus,
      child: Column(children: children),
    );
  }
}
