import 'package:colla_chat/provider/app_data.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/localization.dart';
import '../../../../../routers/routes.dart';
import '../../../../../service/dht/myselfpeer.dart';
import '../../../../../tool/util.dart';

/// 自动邮件发现组件，一个card下的录入框和按钮组合
class AutoDiscovyWidget extends StatefulWidget {
  const AutoDiscovyWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AutoDiscovyWidgetState();
}

class _AutoDiscovyWidgetState extends State<AutoDiscovyWidget>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String _credential = '13609619603';
  String _password = '1234';
  bool _pwdShow = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 30.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.0),
              child: TextFormField(
                keyboardType: TextInputType.text,
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
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
            .navigateTo(context, Application.index, replace: true);
      } else {
        DialogUtil.error(context, content: 'login fail');
      }
    }).catchError((e) {
      DialogUtil.error(context, content: e.toString());
    });
  }

  @override
  bool get wantKeepAlive => true;
}
