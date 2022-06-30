import 'package:colla_chat/widgets/common/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../widgets/common/input_field_widget.dart';

final List<InputFieldDef> p2pRegisterInputFieldDef = [
  InputFieldDef(
      name: 'name', label: 'name', prefixIcon: const Icon(Icons.person)),
  InputFieldDef(
      name: 'loginName',
      label: 'loginName',
      prefixIcon: const Icon(Icons.person)),
  InputFieldDef(
      name: 'email',
      label: 'email',
      prefixIcon: const Icon(Icons.email),
      textInputType: TextInputType.emailAddress),
  InputFieldDef(
      name: 'plainPassword',
      label: 'plainPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password)),
  InputFieldDef(
      name: 'confirmPassword',
      label: 'confirmPassword',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.confirmation_num))
];

/// 用户注册组件，一个card下的录入框和按钮组合
class P2pRegisterWidget extends StatefulWidget {
  const P2pRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pRegisterWidgetState();
}

class _P2pRegisterWidgetState extends State<P2pRegisterWidget>
    with AutomaticKeepAliveClientMixin {
  String _countryCode = 'CN';
  String _mobile = '13609619603';

  @override
  Widget build(BuildContext context) {
    return Card(
        child: SingleChildScrollView(
      child: Column(
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
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: FormInputWidget(
                  inputFieldDefs: p2pRegisterInputFieldDef, onOk: _onOk)),
        ],
      ),
    ));
  }

  _onOk(Map<String, dynamic> values) {
    logger.i(values);
  }

  // Future<void> _register() async {
  //   if (_plainPassword == _confirmPassword) {
  //     var registerStatus = await myselfPeerService.register(
  //         _name, _loginName, _plainPassword,
  //         mobile: _mobile, email: _email);
  //     if (registerStatus) {
  //       Application.router
  //           .navigateTo(context, Application.index, replace: true);
  //     }
  //   } else {
  //     logger.e('password is not matched');
  //   }
  // }

  @override
  bool get wantKeepAlive => true;
}
