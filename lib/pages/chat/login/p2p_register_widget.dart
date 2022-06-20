import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../routers/routes.dart';
import '../../../service/dht/myselfpeer.dart';

/// 用户注册组件，一个card下的录入框和按钮组合
class P2pRegisterWidget extends StatefulWidget {
  const P2pRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pRegisterWidgetState();
}

class _P2pRegisterWidgetState extends State<P2pRegisterWidget>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '胡劲松';
  String _loginName = 'hujs';
  String _countryCode = 'CN';
  String _mobile = '13609619603';
  String _email = 'hujs@colla.cc';
  String _plainPassword = '1234';
  String _confirmPassword = '1234';
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
    Provider.of<AppDataProvider>(context).locale;
    Provider.of<AppDataProvider>(context).themeData;
    Provider.of<AppDataProvider>(context).brightness;
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 30.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: IntlPhoneField(
              initialCountryCode: _countryCode,
              initialValue: _mobile,
              decoration: InputDecoration(
                labelText: AppLocalizations.t('Mobile'),
              ),
              onChanged: (phone) {
                setState(() {
                  _mobile = phone.completeNumber;
                });
              },
              onCountryChanged: (country) {
                setState(() {
                  _countryCode = country.name;
                });
              },
            ),
          ),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: nameController,
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
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                child: Text(AppLocalizations.t('Register')),
                onPressed: () async {
                  await _register();
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

  Future<void> _register() async {
    if (_plainPassword == _confirmPassword) {
      var registerStatus = await myselfPeerService.register(
          _name, _loginName, _plainPassword,
          mobile: _mobile, email: _email);
      if (registerStatus) {
        Application.router
            .navigateTo(context, Application.index, replace: true);
      }
    } else {
      logger.e('password is not matched');
    }
  }

  @override
  bool get wantKeepAlive => true;
}
