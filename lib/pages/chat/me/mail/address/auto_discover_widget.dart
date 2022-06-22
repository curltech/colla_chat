import 'package:flutter/material.dart';

import '../../../../../l10n/localization.dart';
import '../../../../../provider/app_data_provider.dart';
import '../../../../../service/chat/mailaddress.dart';
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
  String _name = '胡劲松';
  String _email = 'hujs06@163.com';
  String _password = 'OZJBOVNGLGCWAZZX';
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
    if (StringUtil.isEmpty(_email) || StringUtil.isEmpty(_name)) {
      logger.e('email or name is empty');
      return;
    }
    await EmailClientPool.instance
        .create(email: _email, name: _name)
        .then((EmailClient? emailClient) {
      if (emailClient != null) {
        if (emailClient.config != null) {
          DialogUtil.info(context, content: 'auto discover successfully');
        } else {
          DialogUtil.error(context, content: 'auto discover failure');
        }
      }
    });
  }

  _connect() {
    if (StringUtil.isEmpty(_email) ||
        StringUtil.isEmpty(_name) ||
        StringUtil.isEmpty(_password)) {
      logger.e('email or name or password is empty');
      return;
    }
    EmailClientPool.instance
        .create(email: _email, name: _name)
        .then((EmailClient? emailClient) {
      if (emailClient != null) {
        var config = emailClient.config;
        if (config != null) {
          emailClient.connect(_password).then((bool success) {
            if (!success) {
              logger.e('connect fail to ${config.displayName}.');
            } else {
              logger.i('connect success to ${config.displayName}.');
              DialogUtil.alert(context, content: '保存为地址吗?')
                  .then((bool? result) async {
                if (result != null && result) {
                  ///保存地址
                  var mailAddress = emailClient.mailAddress;
                  await MailAddressService.instance.store(mailAddress);
                }
              });
            }
          });
        } else {
          logger.e('discover fail.');
        }
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}
