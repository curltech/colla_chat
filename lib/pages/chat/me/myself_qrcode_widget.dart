import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/qrcode_widget.dart';
import 'package:flutter/material.dart';

class MyselfQrcodeWidget extends StatelessWidget with DataTileMixin {
  MyselfQrcodeWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'myself_qrcode';

  @override
  IconData get iconData => Icons.qr_code;

  @override
  String get title => 'Myself Qrcode';

  

  String? content;

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
    var children = <Widget>[
      ListTile(
          leading: myself.avatarImage,
          title: AutoSizeText(name),
          subtitle: AutoSizeText(peerId)),
      const SizedBox(
        height: 40.0,
      ),
      QrcodeWidget(
        content: content!,
        width: 320,
      ),
      const Spacer(),
      AutoSizeText(
        AppLocalizations.t('Scan qrcode, add linkman'),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 30),
    ];
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      child: Column(children: children),
    );
  }
}
