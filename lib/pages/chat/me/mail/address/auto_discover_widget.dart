import 'package:flutter/material.dart';

import '../../../../../l10n/localization.dart';
import '../../../../../tool/util.dart';
import '../../../../../transport/emailclient.dart';

/// 自动邮件发现组件，一个card下的录入框和按钮组合
class AutoDiscoverWidget extends StatefulWidget {
  const AutoDiscoverWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AutoDiscoverWidgetState();
}

class _AutoDiscoverWidgetState extends State<AutoDiscoverWidget>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _pwdShow = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: SingleChildScrollView(
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
                  labelText: AppLocalizations.t('Email'),
                  prefixIcon: Icon(Icons.person),
                ),
                initialValue: _name,
                onChanged: (String val) {
                  setState(() {
                    _name = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 30.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.0),
              child: TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Email'),
                  prefixIcon: Icon(Icons.email),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () async {
                      await _discover();
                    },
                  ),
                ),
                initialValue: _email,
                onChanged: (String val) {
                  setState(() {
                    _email = val;
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
                  AppLocalizations.t('Discover'),
                ),
                onPressed: () async {
                  await _discover();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.t('Connect')),
                onPressed: () async {
                  await _connect();
                },
              )
            ]),
          )
        ],
      ),
    ));
  }

  Future<void> _discover() async {
    var emailClient = await EmailClientPool.instance
        .create(address: _email, personalName: _name);
    if (emailClient != null) {
      if (emailClient.config != null) {
        DialogUtil.info(context, content: 'auto discovry success');
      } else {
        DialogUtil.error(context, content: 'auto discovry fail');
      }
    }
  }

  Future<void> _connect() async {
    var emailClient = await EmailClientPool.instance
        .create(address: _email, personalName: _name);
    if (emailClient != null) {
      if (emailClient.config != null) {
        DialogUtil.info(context, content: 'auto discovry success');
        bool success = await emailClient.connect(_password);
        if (!success) {
          DialogUtil.error(context, content: 'auto connect fail');
        }
      } else {
        DialogUtil.error(context, content: 'auto discovry fail');
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}
