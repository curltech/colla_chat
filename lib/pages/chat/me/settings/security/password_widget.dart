import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> p2pRegisterInputFieldDef = [
  ColumnFieldDef(
      name: 'oldPassword',
      label: 'oldPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.pattern_sharp)),
  ColumnFieldDef(
      name: 'plainPassword',
      label: 'PlainPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password)),
  ColumnFieldDef(
      name: 'confirmPassword',
      label: 'ConfirmPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.confirmation_num))
];

/// 修改用户密码
class PasswordWidget extends StatefulWidget with TileDataMixin {
  const PasswordWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PasswordWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'password';

  @override
  Icon get icon => const Icon(Icons.password);

  @override
  String get title => 'Password';
}

class _PasswordWidgetState extends State<PasswordWidget> {
  Widget _build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              onOk: _onOk,
              okLabel: 'Ok',
              columnFieldDefs: p2pRegisterInputFieldDef,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: Text(AppLocalizations.t(widget.title)),
        child: _build(context));
  }

  _onOk(Map<String, dynamic> values) async {
    String oldPassword = values['oldPassword'];
    String plainPassword = values['plainPassword'];
    String confirmPassword = values['confirmPassword'];
    if (StringUtil.isEmpty(oldPassword)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Please input old password'));
      return;
    }
    if (myself.password == oldPassword) {
      if (StringUtil.isEmpty(plainPassword)) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Please input plain password'));
        return;
      }
      if (StringUtil.isEmpty(confirmPassword)) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Please input confirm password'));
        return;
      }
      if (plainPassword == confirmPassword) {
        String loginName = myself.myselfPeer!.loginName;
        await myselfService.updateMyselfPassword(
            myself.myselfPeer!, plainPassword);
        await myselfPeerService.saveAutoCredential(loginName, plainPassword);
        String peerPrivateKey = myself.myselfPeer!.peerPrivateKey;
        String privateKey = myself.myselfPeer!.privateKey;
        await myselfPeerService.update(
            {'peerPrivateKey': peerPrivateKey, 'privateKey': privateKey},
            where: 'loginName=?',
            whereArgs: [loginName]);
      } else {
        DialogUtil.error(context,
            content: AppLocalizations.t('new password is not matched'));
      }
    } else {
      DialogUtil.error(context,
          content: AppLocalizations.t('old password is not matched'));
    }
  }
}
