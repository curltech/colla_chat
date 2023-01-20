import 'package:barcode_scan2/model/model.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///qrcode二维码增加联系人
class QrcodeLinkmanAddWidget extends StatefulWidget with TileDataMixin {
  QrcodeLinkmanAddWidget({Key? key}) : super(key: key);

  @override
  Icon get icon => const Icon(Icons.qr_code);

  @override
  String get routeName => 'qrcode_linkman_add';

  @override
  String get title => 'Qrcode add linkman';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _QrcodeLinkmanAddWidgetState();
}

class _QrcodeLinkmanAddWidgetState extends State<QrcodeLinkmanAddWidget> {
  String content = '';

  @override
  initState() {
    super.initState();
    QrcodeUtil.scan().then((ScanResult scanResult) {
      logger.i(scanResult.rawContent);
      content = scanResult.rawContent;
    });
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: Text(content));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
