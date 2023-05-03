import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pLoginWidget extends StatefulWidget {
  final void Function(bool result)? onAuthenticate;

  const P2pLoginWidget({Key? key, this.onAuthenticate}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginWidgetState();
}

class _P2pLoginWidgetState extends State<P2pLoginWidget> {
  final List<ColumnFieldDef> p2pLoginInputFieldDef = [
    ColumnFieldDef(
      name: 'credential',
      label: 'Credential(Mobile/Email/LoginName)',
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      ),
      cancel: true,
    ),
    ColumnFieldDef(
      name: 'password',
      label: 'Password',
      inputType: InputType.password,
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lastLogin();
  }

  ///获取最后一次登录的用户名
  _lastLogin() async {
    String? credential = await myselfPeerService.lastCredentialName();
    if (StringUtil.isNotEmpty(credential)) {
      ColumnFieldDef def = p2pLoginInputFieldDef[0];
      def.initValue = credential;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const SizedBox(
        height: 50,
      ),
      ImageUtil.buildImageWidget(
        image: 'assets/images/colla.png',
        height: AppImageSize.xlSize,
        width: AppImageSize.xlSize,
      ),
      const SizedBox(
        height: 50,
      ),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: FormInputWidget(
            mainAxisAlignment: MainAxisAlignment.start,
            height: 200,
            spacing: 10.0,
            onOk: _login,
            okLabel: 'Login',
            columnFieldDefs: p2pLoginInputFieldDef,
          )),
    ]);
  }

  _login(Map<String, dynamic> values) async {
    String? credential = values[credentialName];
    String? password = values[passwordName];
    if (credential == null) {
      DialogUtil.error(context, content: 'Must have node credential');
      return;
    }
    if (password == null) {
      DialogUtil.error(context, content: 'Must have node password');
      return;
    }
    try {
      DialogUtil.loadingShow(context);
      bool loginStatus = await myselfPeerService.login(credential, password);
      if (mounted) {
        DialogUtil.loadingHide(context);
      }
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(loginStatus);
      } else {
        if (loginStatus) {
          if (myself.autoLogin) {
            myselfPeerService.saveAutoCredential(credential, password);
          }

          if (mounted) {
            Application.router
                .navigateTo(context, Application.index, replace: true);
          }
        } else {
          if (mounted) {
            DialogUtil.error(context,
                content: AppLocalizations.t('Login fail'));
          }
        }
      }
    } catch (e) {
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(false);
      } else {
        DialogUtil.error(context, content: e.toString());
      }
    }
  }
}
