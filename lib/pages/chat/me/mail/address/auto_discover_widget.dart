import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:enough_mail/discover.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/localization.dart';
import '../../../../../service/chat/mailaddress.dart';
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
  ClientConfig? config;

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
    EmailMessageUtil.discover(_email).then((ClientConfig? config) {
      if (config != null) {
        DialogUtil.info(context, content: 'auto discover successfully');
        this.config = config;
      } else {
        DialogUtil.error(context, content: 'auto discover failure');
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
    var config = this.config;
    if (config == null) {
      logger.e('auto dicover config is null');
      return;
    }
    var mailAddress =
        EmailMessageUtil.buildDiscoverMailAddress(_email, _name, config);
    EmailClientPool.instance
        .create(mailAddress, _password, config: this.config)
        .then((EmailClient? emailClient) {
      if (emailClient == null) {
        logger.e('create (or connect) fail to $_name.');
        return;
      }
      logger.i('create (or connect) success to $_name.');
      DialogUtil.alert(context, content: '保存为地址吗?').then((bool? result) async {
        if (result != null && result) {
          ///保存地址
          await mailAddressService.store(mailAddress);
        }
      });
    });
  }

  @override
  bool get wantKeepAlive => true;
}
