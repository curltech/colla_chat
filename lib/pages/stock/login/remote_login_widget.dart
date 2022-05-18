import 'package:flutter/material.dart';

import '../../../entity/stock/user.dart';
import '../../../routers/application.dart';
import '../../../routers/routes.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class RemoteLoginWidget extends StatefulWidget {
  const RemoteLoginWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteLoginWidgetState();
}

class _RemoteLoginWidgetState extends State<RemoteLoginWidget> {
  final _formKey = GlobalKey<FormState>();
  String _credential = '';
  String _password = '';
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
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _credentialController,
                decoration: InputDecoration(
                  labelText: '登录凭证(手机/邮件/登录名)',
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (String val) {
                  setState(() {
                    _credential = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 30.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.0),
              child: TextField(
                keyboardType: TextInputType.text,
                obscureText: !_pwdShow,
                //controller: passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
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
                onChanged: (String val) {
                  setState(() {
                    _password = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 30.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.0),
            child: Row(children: [
              TextButton(
                child: Text('登录'),
                onPressed: () async {
                  _login();
                },
              ),
              TextButton(
                child: Text('重置'),
                onPressed: () async {},
              )
            ]),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    var current = await user.login('/user/Login', {
      'credential_': _credential,
      'password_': _password,
    });
    if (user.loginStatus == true) {
      Application.router.navigateTo(context, Routes.index, replace: true);
    }
  }
}
