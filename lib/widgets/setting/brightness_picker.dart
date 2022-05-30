import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constant/brightness.dart';
import '../../provider/locale_data.dart';
import '../../provider/theme_data.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

class BrightnessPicker extends StatefulWidget {
  const BrightnessPicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BrightnessPickerState();
  }
}

class _BrightnessPickerState extends State<BrightnessPicker> {
  List<S2Choice<String>> _items = [];
  @override
  Widget build(BuildContext context) {
    var selectedLocale = Provider.of<LocaleDataProvider>(context).locale;
    var brightnessOptions = brightnessOptionsISO[
        '${selectedLocale.languageCode}_${selectedLocale.countryCode}'];
    _items = [];
    if (brightnessOptions != null) {
      for (var brightnessOption in brightnessOptions) {
        var item = S2Choice<String>(
            value: brightnessOption.value, title: brightnessOption.label);
        _items.add(item);
      }
    }
    return Consumer<ThemeDataProvider>(
      builder: (context, themeData, child) => SmartSelect<String>.single(
        modalType: S2ModalType.bottomSheet,
        placeholder: '请选择亮度',
        title: '请选择亮度',
        selectedValue: Provider.of<ThemeDataProvider>(context).brightness,
        choiceItems: _items,
        onChange: (dynamic state) {
          if (state != null) {
            String brightness = state.value;
            themeData.brightness = brightness;
          }
        },
      ),
    );
  }
}
