import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class RemoteRegisterWidget extends StatefulWidget {
  const RemoteRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteRegisterWidgetState();
}

class _RemoteRegisterWidgetState extends State<RemoteRegisterWidget> {
  final _formKey = GlobalKey<FormState>();
  String _name = '胡劲松';
  String _loginName = 'hujs';
  String _mobile = '13609619603';
  String _email = 'hujs@colla.cc';
  String _plainPassword = '123456';
  String _confirmPassword = '123456';
  bool _pwdShow = false;

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    nameController.addListener(() {
      setState(() {
        _name = nameController.text;
      });
    });
    TextEditingController loginNameController = TextEditingController();
    loginNameController.addListener(() {
      setState(() {
        _loginName = loginNameController.text;
      });
    });
    TextEditingController mobileController = TextEditingController();
    mobileController.addListener(() {
      setState(() {
        _mobile = mobileController.text;
      });
    });
    TextEditingController emailController = TextEditingController();
    emailController.addListener(() {
      setState(() {
        _email = emailController.text;
      });
    });
    TextEditingController plainPasswordController = TextEditingController();
    plainPasswordController.addListener(() {
      setState(() {
        _plainPassword = plainPasswordController.text;
      });
    });
    TextEditingController confirmPasswordController = TextEditingController();
    confirmPasswordController.addListener(() {
      setState(() {
        _confirmPassword = confirmPasswordController.text;
      });
    });
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Username'),
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
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: loginNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('LoginName'),
                  prefixIcon: Icon(Icons.desktop_mac),
                ),
                initialValue: _loginName,
                onChanged: (String val) {
                  setState(() {
                    _loginName = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: mobileController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Mobile'),
                  prefixIcon: Icon(Icons.mobile_friendly),
                ),
                initialValue: _mobile,
                onChanged: (String val) {
                  setState(() {
                    _mobile = val;
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
                initialValue: _plainPassword,
                onChanged: (String val) {
                  setState(() {
                    _plainPassword = val;
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
                  labelText: AppLocalizations.t('Confirm Password'),
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
                initialValue: _confirmPassword,
                onChanged: (String val) {
                  setState(() {
                    _confirmPassword = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(children: [
              TextButton(
                child: Text(AppLocalizations.t('Register')),
                onPressed: () async {},
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
}
