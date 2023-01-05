import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

final List<ColumnFieldDef> p2pRegisterInputFieldDef = [
  ColumnFieldDef(
      name: 'oldPassword',
      label: 'oldPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.pattern_sharp)),
  ColumnFieldDef(
      name: 'plainPassword',
      label: 'PlainPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password)),
  ColumnFieldDef(
      name: 'confirmPassword',
      label: 'ConfirmPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.confirmation_num))
];

/// 修改用户密码
class PasswordWidget extends StatefulWidget {
  const PasswordWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PasswordWidgetState();
}

class _PasswordWidgetState extends State<PasswordWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              onOk: _onOk,
              okLabel: 'Register',
              columnFieldDefs: p2pRegisterInputFieldDef,
            )),
      ],
    );
  }

  _onOk(Map<String, dynamic> values) {
    String plainPassword = values['plainPassword'];
    String confirmPassword = values['confirmPassword'];
    if (plainPassword == confirmPassword) {
    } else {
      logger.e('password is not matched');
    }
  }
}
