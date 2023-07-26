import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CommonTextFormField(
                controller: nameController,
                labelText: AppLocalizations.t('Username'),
                prefixIcon: const Icon(Icons.person),
                initialValue: _name,
                onChanged: (String val) {
                  setState(() {
                    _name = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          const SizedBox(height: 10.0),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CommonTextFormField(
                //controller: loginNameController,
                labelText: AppLocalizations.t('LoginName'),
                prefixIcon: const Icon(Icons.desktop_mac),
                initialValue: _loginName,
                onChanged: (String val) {
                  setState(() {
                    _loginName = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          const SizedBox(height: 10.0),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CommonTextFormField(
                //controller: mobileController,
                labelText: AppLocalizations.t('Mobile'),
                prefixIcon: const Icon(Icons.mobile_friendly),
                initialValue: _mobile,
                onChanged: (String val) {
                  setState(() {
                    _mobile = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          const SizedBox(height: 10.0),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CommonTextFormField(
                //controller: emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: AppLocalizations.t('Email'),
                prefixIcon: const Icon(Icons.email),
                initialValue: _email,
                onChanged: (String val) {
                  setState(() {
                    _email = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          const SizedBox(height: 10.0),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CommonTextFormField(
                keyboardType: TextInputType.text,
                obscureText: !_pwdShow,
                //controller: passwordController,
                labelText: AppLocalizations.t('Password'),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon:
                      Icon(_pwdShow ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _pwdShow = !_pwdShow;
                    });
                  },
                ),
                initialValue: _plainPassword,
                onChanged: (String val) {
                  setState(() {
                    _plainPassword = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          const SizedBox(height: 10.0),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CommonTextFormField(
                keyboardType: TextInputType.text,
                obscureText: !_pwdShow,
                //controller: passwordController,
                labelText: AppLocalizations.t('Confirm Password'),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon:
                      Icon(_pwdShow ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _pwdShow = !_pwdShow;
                    });
                  },
                ),
                initialValue: _confirmPassword,
                onChanged: (String val) {
                  setState(() {
                    _confirmPassword = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(children: [
              TextButton(
                child: CommonAutoSizeText(AppLocalizations.t('Register')),
                onPressed: () async {},
              ),
              TextButton(
                child: CommonAutoSizeText(AppLocalizations.t('Reset')),
                onPressed: () async {},
              )
            ]),
          )
        ],
      ),
    );
  }
}
