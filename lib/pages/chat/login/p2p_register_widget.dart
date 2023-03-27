import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

final List<ColumnFieldDef> p2pRegisterInputFieldDef = [
  ColumnFieldDef(
      name: 'name',
      label: 'Name',
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      ),
      initValue: '胡劲松'),
  ColumnFieldDef(
      name: 'loginName',
      label: 'LoginName',
      prefixIcon: Icon(
        Icons.mobile_friendly,
        color: myself.primary,
      ),
      initValue: '13609619603'),
  ColumnFieldDef(
      name: 'email',
      label: 'Email',
      prefixIcon: Icon(
        Icons.email,
        color: myself.primary,
      ),
      initValue: 'hujs@colla.cc',
      textInputType: TextInputType.emailAddress),
  ColumnFieldDef(
      name: 'plainPassword',
      label: 'PlainPassword',
      inputType: InputType.password,
      initValue: '1234',
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'confirmPassword',
      label: 'ConfirmPassword',
      inputType: InputType.password,
      initValue: '1234',
      prefixIcon: Icon(
        Icons.confirmation_num,
        color: myself.primary,
      ))
];

/// 用户注册组件，一个card下的录入框和按钮组合
class P2pRegisterWidget extends StatefulWidget {
  const P2pRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pRegisterWidgetState();
}

class _P2pRegisterWidgetState extends State<P2pRegisterWidget> {
  String _countryCode = 'CN';
  String _mobile = '13609619603';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const SizedBox(height: 30.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: IntlPhoneField(
            initialCountryCode: _countryCode,
            initialValue: _mobile,
            decoration: InputDecoration(
              labelText: AppLocalizations.t('Mobile'),
            ),
            onChanged: (PhoneNumber phoneNumber) {
              setState(() {
                _mobile = phoneNumber.number;
              });
            },
            onCountryChanged: (country) {
              setState(() {
                _countryCode = country.name;
              });
            },
            disableLengthCheck: true,
          ),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              height: 320,
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
    String name = values['name'];
    String loginName = values['loginName'];
    String email = values['email'];
    if (plainPassword == confirmPassword) {
      myselfPeerService
          .register(name, loginName, plainPassword,
              mobile: _mobile, email: email)
          .then((myselfPeer) {
        myself.myselfPeer = myselfPeer;
        Application.router
            .navigateTo(context, Application.p2pLogin, replace: true);
      }).onError((error, stackTrace) {
        DialogUtil.error(context, content: error.toString());
      });
    } else {
      logger.e('password is not matched');
    }
  }
}
