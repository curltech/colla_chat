import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routers/routes.dart';
import '../../../service/dht/myselfpeer.dart';
import '../../../tool/util.dart';
import '../../../widgets/common/column_field_widget.dart';
import '../../../widgets/common/form_input_widget.dart';

final List<ColumnFieldDef> p2pRegisterInputFieldDef = [
  ColumnFieldDef(
      name: 'credential',
      label: 'Credentia(Mobile/Email/LoginName)',
      prefixIcon: const Icon(Icons.person),
      cancel: true,
      initValue: '13609619603'),
  ColumnFieldDef(
    name: 'password',
    label: 'password',
    inputType: InputType.password,
    initValue: '123456',
    prefixIcon: const Icon(Icons.lock),
  ),
];

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pLoginWidget extends StatefulWidget {
  const P2pLoginWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginWidgetState();
}

class _P2pLoginWidgetState extends State<P2pLoginWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AppDataProvider>(context);
    return Card(
        child: Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: FormInputWidget(
            mainAxisAlignment: MainAxisAlignment.center,
            onOk: _login,
            columnFieldDefs: p2pRegisterInputFieldDef,
          )),
    ));
  }

  _login(Map<String, dynamic> values) {
    AppDataProvider appParams = AppDataProvider.instance;
    appParams.saveAppParams();
    String credential = values['credential'];
    String password = values['password'];
    myselfPeerService.login(credential, password).then((bool loginStatus) {
      if (loginStatus) {
        Application.router
            .navigateTo(context, Application.index, replace: true);
      } else {
        DialogUtil.error(context, content: 'login fail');
      }
    }).catchError((e) {
      DialogUtil.error(context, content: e.toString());
    });
  }
}
