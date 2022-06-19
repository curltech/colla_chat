import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/localization.dart';

/// 邮件地址手工注册组件，一个card下的录入框和按钮组合
class ManualAddWidget extends StatefulWidget {
  const ManualAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ManualAddWidgetState();
}

class _ManualAddWidgetState extends State<ManualAddWidget>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String? _personalName;
  String? _password;
  String? _email;
  String? _imapServerHost;
  String? _imapServerPort;
  bool _imapServerSecure = true;
  String? _popServerHost;
  String? _popServerPort;
  bool _popServerSecure = true;
  String? _smtpServerHost;
  String? _smtpServerPort;
  bool _smtpServerSecure = true;
  bool _pwdShow = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Username'),
                  prefixIcon: Icon(Icons.person),
                ),
                initialValue: _personalName,
                onChanged: (String val) {
                  setState(() {
                    _personalName = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Email'),
                  prefixIcon: Icon(Icons.email),
                ),
                initialValue: _email,
                onChanged: (String val) {
                  setState(() {
                    _email = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
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
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('SmtpServerHost'),
                  prefixIcon: Icon(Icons.desktop_mac),
                ),
                initialValue: _smtpServerHost,
                onChanged: (String val) {
                  setState(() {
                    _smtpServerHost = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('SmtpServerPort'),
                  prefixIcon: Icon(Icons.router),
                ),
                initialValue: _smtpServerPort,
                onChanged: (String val) {
                  setState(() {
                    _smtpServerPort = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                child: Text(AppLocalizations.t('Connect')),
                onPressed: () async {
                  await _connect();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.t('Add')),
                onPressed: () async {},
              )
            ]),
          )
        ],
      ),
    );
  }

  Future<void> _connect() async {}

  @override
  bool get wantKeepAlive => true;
}
