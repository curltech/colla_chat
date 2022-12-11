import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
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
      prefixIcon: const Icon(Icons.person),
      cancel: true,
    ),
    ColumnFieldDef(
      name: 'password',
      label: 'Password',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lastLogin();
    _skipLogin();
  }

  ///获取最后一次登录的用户名
  _lastLogin() async {
    String? credential = await myselfPeerService.lastCredentialName();
    if (StringUtil.isNotEmpty(credential)) {
      ColumnFieldDef credential = p2pLoginInputFieldDef[0];
      credential.initValue = credential;
    }
  }

  ///获取最后一次登录的用户名和密码，如果都存在，快捷登录
  _skipLogin() async {
    Map<String, dynamic>? skipLogin = await myselfPeerService.credential();
    if (skipLogin != null) {
      String? credential = skipLogin[credentialName];
      String? password = skipLogin[passwordName];
      if (StringUtil.isNotEmpty(credential) &&
          StringUtil.isNotEmpty(password)) {
        _login(skipLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(
        height: 50,
      ),
      ImageUtil.buildImageWidget(
        image: 'assets/images/colla.png',
        height: 128,
        width: 128,
      ),
      const SizedBox(
        height: 50,
      ),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: FormInputWidget(
            mainAxisAlignment: MainAxisAlignment.center,
            onOk: _login,
            okLabel: 'Login',
            columnFieldDefs: p2pLoginInputFieldDef,
          ))
    ]);
  }

  _login(Map<String, dynamic> values) {
    appDataProvider.saveAppParams();
    String credential = values[credentialName];
    String password = values[passwordName];
    myselfPeerService.login(credential, password).then((bool loginStatus) {
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(loginStatus);
      } else {
        if (loginStatus) {
          myselfPeerService.saveCredential(credential, password);
          Application.router
              .navigateTo(context, Application.index, replace: true);
        } else {
          DialogUtil.error(context, content: AppLocalizations.t('Login fail'));
        }
      }
    }).catchError((e) {
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(false);
      } else {
        DialogUtil.error(context, content: e.toString());
      }
    });
  }
}
