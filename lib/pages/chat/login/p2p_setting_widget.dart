import 'package:colla_chat/constant/brightness.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

import '../../../widgets/data_bind/data_select.dart';
import 'ws_address_picker.dart';

/// 地址语言选择设置组件，一个card下的录入框和按钮组合
class P2pSettingWidget extends StatefulWidget {
  const P2pSettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pSettingWidgetState();
}

class _P2pSettingWidgetState extends State<P2pSettingWidget> {
  @override
  Widget build(BuildContext context) {
    var padding = const EdgeInsets.symmetric(horizontal: 15.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 30.0),
        Padding(
          padding: padding,
          child: DataSelect(
              label: 'Locale',
              hint: 'Please select locale',
              items: localeOptions,
              onChanged: (String? value) {
                if (value != null) {
                  appDataProvider.locale = value;
                }
              }),
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: padding,
          child: const WsAddressPicker(),
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: padding,
          child: DataSelect(
              label: 'Brightness',
              hint: 'Please select brightness',
              items: brightnessOptions,
              onChanged: (String? value) {
                if (value != null) {
                  appDataProvider.brightness = value;
                }
              }),
        ),
      ],
    );
  }
}
