import 'package:colla_chat/provider/app_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/localization.dart';
import '../../../routers/application.dart';
import '../../../routers/routes.dart';
import '../../../service/dht/myselfpeer.dart';

import '../../../tool/util.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pLoginWidget extends StatefulWidget {
  const P2pLoginWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginWidgetState();
}

class _P2pLoginWidgetState extends State<P2pLoginWidget> {
  final _formKey = GlobalKey<FormState>();
  String _credential = '13609619603';
  String _password = '1234';
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
    Provider.of<AppDataProvider>(context).locale;
    Provider.of<AppDataProvider>(context).themeData;
    Provider.of<AppDataProvider>(context).brightness;
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
                      AppLocalizations.t('Credentia(Mobile/Email/LoginName)'),
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
                child: Text(
                  AppLocalizations.t('Login'),
                ),
                onPressed: () async {
                  await _login();
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
    AppDataProvider appParams = AppDataProvider.instance;
    await appParams.saveAppParams();
    myselfPeerService.login(_credential, _password).then((bool loginStatus) {
      if (loginStatus) {
        Application.router
            .navigateTo(context, Routes.index, replace: true);
      } else {
        DialogUtil.error(context, content: 'login fail');
      }
    }).catchError((e) {
      DialogUtil.error(context, content: e.toString());
    });
  }
}
