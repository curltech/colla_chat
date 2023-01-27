import 'package:colla_chat/pages/chat/me/settings/advanced/ws_address_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';

/// 地址语言选择设置组件，一个card下的录入框和按钮组合
class P2pSettingWidget extends StatefulWidget {
  const P2pSettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pSettingWidgetState();
}

class _P2pSettingWidgetState extends State<P2pSettingWidget> {
  @override
  void initState() {
    super.initState();
    myself.addListener(_update);
  }

  _update() {
    setState(() {});
  }

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
          child: const LocalePicker(),
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: padding,
          child: const WsAddressPicker(),
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: padding,
          child: const BrightnessPicker(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    super.dispose();
  }
}
