import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../app.dart';
import '../../../routers/application.dart';
import '../../../routers/routes.dart';
import '../../../service/dht/myselfpeer.dart';
import '../../../tool/util.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pRegisterWidget extends StatefulWidget {
  const P2pRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pRegisterWidgetState();
}

class _P2pRegisterWidgetState extends State<P2pRegisterWidget> {
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
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: IntlPhoneField(
              initialCountryCode: _countryCode,
              initialValue: _mobile,
              decoration: InputDecoration(
                labelText: '电话',
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
                  labelText: '用户名',
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
                  labelText: '登录名',
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
                  labelText: '邮箱',
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
                  labelText: '确认密码',
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
                child: Text('注册'),
                onPressed: () async {
                  await _register();
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

  Future<void> _register() async {
    if (_plainPassword == _confirmPassword) {
      var registerStatus = await myselfPeerService.register(
          _name, _loginName, _plainPassword,
          mobile: _mobile, email: _email);
      if (registerStatus) {
        Application.router
            .navigateTo(context, Routes.mobileIndex, replace: true);
      }
    } else {
      logger.e('password is not matched');
    }
  }
}
