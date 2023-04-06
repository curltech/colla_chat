import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/mobile_util.dart';
import 'package:colla_chat/tool/phone_number_util.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;

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
  TextEditingController mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mobileController.text = '13609619603';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: IntlPhoneField(
            controller: mobileController,
            initialCountryCode: _countryCode,
            decoration: InputDecoration(
              labelText: AppLocalizations.t('Mobile'),
              suffixIcon: platformParams.android
                  ? IconButton(
                      onPressed: () async {
                        String? mobile = await MobileUtil.getMobileNumber();
                        if (mobile != null) {
                          int pos = mobile.indexOf('+');
                          if (pos > -1) {
                            mobile = mobile.substring(pos);
                          }
                          phone_numbers_parser.PhoneNumber phoneNumber =
                              PhoneNumberUtil.fromRaw(mobile);
                          mobileController.text = phoneNumber.nsn;
                        }
                      },
                      icon: Icon(
                        Icons.mobile_screen_share,
                        color: myself.primary,
                      ))
                  : null,
            ),
            onChanged: (PhoneNumber phoneNumber) {
              // mobileController.text = phoneNumber.number;
            },
            onCountryChanged: (country) {
              _countryCode = country.name;
            },
            disableLengthCheck: true,
          ),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              height: 460,
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
              mobile: mobileController.text, email: email)
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
