import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

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
    myself.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    List<Option<ThemeMode>> themeModeChoices = [];
    for (var themeModeOption in ThemeMode.values) {
      Option<ThemeMode> item =
          Option<ThemeMode>(themeModeOption.name, themeModeOption);
      themeModeChoices.add(item);
    }
    return SmartSelectUtil.single<ThemeMode>(
      title: 'Brightness',
      placeholder: 'Select one brightness',
      onChange: (selected) {
        if (selected != null) {
          myself.themeMode = selected;
        }
      },
      items: themeModeChoices,
      selectedValue: myself.themeMode,
    );
  }

  Widget _buildToggleWidget(BuildContext context) {
    final List<bool> isSelected = <bool>[
      myself.themeMode == ThemeMode.light,
      myself.themeMode == ThemeMode.system,
      myself.themeMode == ThemeMode.dark,
    ];
    var toggleWidget = ToggleButtons(
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          myself.themeMode = ThemeMode.light;
        } else if (newIndex == 1) {
          myself.themeMode = ThemeMode.system;
        } else {
          myself.themeMode = ThemeMode.dark;
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
    myself.removeListener(_update);
    super.dispose();
  }
}
