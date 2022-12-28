import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/color_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

/// 一般设置组件，包括颜色，亮度，语言
class GeneralSettingWidget extends StatefulWidget {
  const GeneralSettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GeneralSettingWidgetState();
}

class _GeneralSettingWidgetState extends State<GeneralSettingWidget> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
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
          child: const ColorPicker(),
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
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
