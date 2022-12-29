import 'package:colla_chat/constant/brightness.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

class BrightnessPicker extends StatefulWidget {
  const BrightnessPicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BrightnessPickerState();
  }
}

class _BrightnessPickerState extends State<BrightnessPicker> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    List<Option<String>> brightnessChoices = [];
    for (var brightnessOption in brightnessOptions) {
      Option<String> item =
          Option<String>(brightnessOption.label, brightnessOption.value);
      brightnessChoices.add(item);
    }
    return SmartSelectUtil.single<String>(
      title: 'Brightness',
      placeholder: 'Select one brightness',
      onChange: (selected) {
        if (selected != null) {
          appDataProvider.brightness = selected;
        }
      },
      items: brightnessChoices,
      selectedValue: appDataProvider.brightness,
    );
  }

  Widget _buildToggleWidget(BuildContext context) {
    final List<bool> isSelected = <bool>[
      appDataProvider.brightness == ThemeMode.light.name,
      appDataProvider.brightness == ThemeMode.system.name,
      appDataProvider.brightness == ThemeMode.dark.name,
    ];
    var toggleWidget = ToggleButtons(
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          appDataProvider.brightness = ThemeMode.light.name;
        } else if (newIndex == 1) {
          appDataProvider.brightness = ThemeMode.system.name;
        } else {
          appDataProvider.brightness = ThemeMode.dark.name;
        }
      },
      children: const <Widget>[
        Icon(Icons.wb_sunny),
        Icon(Icons.phone_iphone),
        Icon(Icons.bedtime),
      ],
    );

    return Row(children: [
      Text(AppLocalizations.t('Brightness')),
      const Spacer(),
      toggleWidget,
      const SizedBox(
        width: 10,
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildToggleWidget(context);
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
