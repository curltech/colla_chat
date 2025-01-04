import 'package:colla_chat/pages/chat/me/settings/advanced/ws_address_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:flutter/material.dart';

/// 地址语言选择设置组件，一个card下的录入框和按钮组合
class P2pSettingWidget extends StatelessWidget {
  const P2pSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var padding = const EdgeInsets.symmetric(horizontal: 15.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 30.0),
        Container(
          padding: padding,
          child: const LocalePicker(),
        ),
        const SizedBox(height: 10.0),
        Container(
          padding: padding,
          child: WsAddressPicker(),
        ),
        const SizedBox(height: 10.0),
        Container(
          padding: padding,
          child: const BrightnessPicker(),
        ),
      ],
    );
  }
}
