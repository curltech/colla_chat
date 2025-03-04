import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:regexpattern/regexpattern.dart';

final List<PlatformDataField> passwordInputFieldDef = [
  PlatformDataField(
      name: 'oldPassword',
      label: 'oldPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.pattern_sharp)),
  PlatformDataField(
      name: 'plainPassword',
      label: 'PlainPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password)),
  PlatformDataField(
      name: 'confirmPassword',
      label: 'ConfirmPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.confirmation_num))
];

/// 修改用户密码
class PasswordWidget extends StatelessWidget with TileDataMixin {
  PasswordWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'password';

  @override
  IconData get iconData => Icons.password;

  @override
  String get title => 'Password';

  @override
  String? get information => null;

  final FormInputController controller =
      FormInputController(passwordInputFieldDef);

  Widget _buildPasswordWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              height: 250,
              onOk: (Map<String, dynamic> values) {
                _onOk(context, values);
              },
              okLabel: 'Ok',
              controller: controller,
            )),
      ],
    );
  }

  _onOk(BuildContext context, Map<String, dynamic> values) async {
    String oldPassword = values['oldPassword'];
    String plainPassword = values['plainPassword'];
    String confirmPassword = values['confirmPassword'];
    if (StringUtil.isEmpty(oldPassword)) {
      DialogUtil.error(
          content: AppLocalizations.t('Please input old password'));
      return;
    }
    if (myself.password == oldPassword) {
      if (StringUtil.isEmpty(plainPassword)) {
        DialogUtil.error(
            content: AppLocalizations.t('Please input plain password'));
        return;
      }
      if (StringUtil.isEmpty(confirmPassword)) {
        DialogUtil.error(
            content: AppLocalizations.t('Please input confirm password'));
        return;
      }
      // 检查密码的难度
      bool isPassword =
          RegVal.hasMatch(plainPassword, RegexPattern.passwordNormal1);
      // isPassword = Validate.isPassword(plainPassword);
      if (!isPassword) {
        DialogUtil.error(content: 'password must be strong password');
        return;
      }
      if (plainPassword != confirmPassword) {
        logger.e('new password is not matched');
        DialogUtil.error(content: 'password is not matched');
        return;
      }
      String loginName = myself.myselfPeer.loginName;
      await myselfService.updateMyselfPassword(
          myself.myselfPeer, plainPassword);
      if (myself.peerProfile.autoLogin) {
        await myselfPeerService.saveAutoCredential(loginName, plainPassword);
      }
      String peerPrivateKey = myself.myselfPeer.peerPrivateKey;
      String privateKey = myself.myselfPeer.privateKey;
      await myselfPeerService.update(
          {'peerPrivateKey': peerPrivateKey, 'privateKey': privateKey},
          where: 'loginName=?',
          whereArgs: [loginName]);
    } else {
      DialogUtil.error(
          content: AppLocalizations.t('old password is not matched'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true, title: title, child: _buildPasswordWidget(context));
  }
}
