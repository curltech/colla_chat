import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

import '../../../entity/stock/user.dart';
import '../../../l10n/localization.dart';
import '../../../routers/routes.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class RemoteLoginWidget extends StatefulWidget {
  const RemoteLoginWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteLoginWidgetState();
}

class _RemoteLoginWidgetState extends State<RemoteLoginWidget> {
  final _formKey = GlobalKey<FormState>();
  String _credential = '13609619603';
  String _password = '123456';
  bool _pwdShow = false;
  late TextEditingController _credentialController;

  @override
  void initState() {
    super.initState();
    // 初始化子项集合
    _credentialController = TextEditingController(text: '13609619603');
    _credentialController.addListener(() {
      setState(() {
        _credential = _credentialController.text;
      });
    });
    TextEditingController passwordController = TextEditingController();
    passwordController.addListener(() {
      setState(() {
        _password = passwordController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.0),
              child: TextFormField(
                keyboardType: TextInputType.text,
                //controller: _credentialController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.t('Credential(Mobile/Email/LoginName)'),
                  prefixIcon: Icon(Icons.person),
                ),
                initialValue: _credential,
                onChanged: (String val) {
                  setState(() {
                    _credential = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 30.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.0),
              child: TextFormField(
                keyboardType: TextInputType.text,
                obscureText: !_pwdShow,
                //controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Password'),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _pwdShow ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _pwdShow = !_pwdShow;
                      });
                    },
                  ),
                ),
                initialValue: _password,
                onChanged: (String val) {
                  setState(() {
                    _password = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 30.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.0),
            child: Row(children: [
              TextButton(
                child: Text(AppLocalizations.t('Login')),
                onPressed: () async {
                  _login();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.t('Reset')),
                onPressed: () async {},
              )
            ]),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    AppDataProvider appParams = await AppDataProvider.instance;
    await appParams.saveAppParams();
    var current = await stockUser.login('/user/Login', {
      'credential_': _credential,
      'password_': _password,
    });
    if (stockUser.loginStatus == true) {
      Application.router.navigateTo(context, Application.index, replace: true);
    }
  }
}
