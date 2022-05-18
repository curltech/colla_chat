import 'package:flutter/material.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class RemoteRegisterWidget extends StatefulWidget {
  const RemoteRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteRegisterWidgetState();
}

class _RemoteRegisterWidgetState extends State<RemoteRegisterWidget> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _username = '';
  String _mobile = '';
  String _email = '';
  String _plainPassword = '';
  String _confirmPassword = '';
  bool _pwdShow = false;

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    nameController.addListener(() {
      setState(() {
        _name = nameController.text;
      });
    });
    TextEditingController usernameController = TextEditingController();
    usernameController.addListener(() {
      setState(() {
        _username = usernameController.text;
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
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (String val) {
                  setState(() {
                    _name = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                //controller: usernameController,
                decoration: InputDecoration(
                  labelText: '登录名',
                  prefixIcon: Icon(Icons.desktop_mac),
                ),
                onChanged: (String val) {
                  setState(() {
                    _username = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                //controller: mobileController,
                decoration: InputDecoration(
                  labelText: '手机',
                  prefixIcon: Icon(Icons.mobile_friendly),
                ),
                onChanged: (String val) {
                  setState(() {
                    _mobile = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                //controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.email),
                ),
                onChanged: (String val) {
                  setState(() {
                    _email = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
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
                    _plainPassword = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
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
                onChanged: (String val) {
                  setState(() {
                    _confirmPassword = val;
                  });
                },
                onSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(children: [
              TextButton(
                child: Text('注册'),
                onPressed: () async {},
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
}
