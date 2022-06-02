import 'package:colla_chat/widgets/setting/locale_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app.dart';
import '../../../l10n/localization.dart';
import '../../../widgets/setting/brightness_picker.dart';
import '../../../widgets/setting/ws_address_picker.dart';

/// 地址语言选择设置组件，一个card下的录入框和按钮组合
class P2pSettingWidget extends StatefulWidget {
  const P2pSettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pSettingWidgetState();
}

class _P2pSettingWidgetState extends State<P2pSettingWidget> {
  final _formKey = GlobalKey<FormState>();
  var _offstage = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: LocalePicker(),
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: WsAddressPicker(),
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: BrightnessPicker(),
          ),
          SizedBox(height: 10.0),
          Offstage(
            offstage: _offstage,
            child: Container(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    //controller: passwordController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.instance.text('Customized address'),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    initialValue: '',
                    onChanged: (String val) {
                      var appParams = AppParams.instance;
                      appParams.wsConnectAddress[0] = val;
                    },
                    onFieldSubmitted: (String val) {},
                  )),
            ),
          )
        ],
      ),
    );
  }
}
