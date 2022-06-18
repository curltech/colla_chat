import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

import '../../../../entity/dht/myself.dart';
import '../../../../tool/util.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/image_widget.dart';
import '../../chat/widget/ui.dart';

class QrcodeWidget extends StatelessWidget
    with BackButtonMixin, RouteNameMixin {
  String? content;

  final List<String> menus = ['换个样式', '保存到手机', '扫描二维码', '重置二维码'];

  QrcodeWidget({Key? key, this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String name;
    var peerId = myself.peerId;
    if (peerId == null) {
      peerId = '未登录';
      name = '未登录';
    } else {
      name = myself.myselfPeer!.name;
    }
    content ??= peerId;
    var children = <Widget>[
      ListTile(
          leading: const ImageWidget(
            width: 32.0,
            height: 32.0,
          ),
          title: Text(name),
          subtitle: Text(peerId)),
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: QrcodeUtil.create(content!),
      ),
      Space(height: 2.0),
      const Text('扫一扫上面的二维码图案，加我微信'),
    ];
    return AppBarView(
      title: '二维码',
      withBack: withBack,
      rightActions: menus,
      child: Column(children: children),
    );
  }

  @override
  bool get withBack => true;

  @override
  String get routeName => 'qrcode';
}
