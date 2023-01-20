import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flex_color_picker/flex_color_picker.dart' as flex;
import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ColorPickerState();
  }
}

class _ColorPickerState extends State<ColorPicker> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
    myself.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Future<bool> colorPickerDialog() async {
    ThemeData themeData = myself.themeData;
    return flex.ColorPicker(
      color: myself.seedColor,
      onColorChanged: (Color color) {
        myself.seedColor = color;
      },
      width: 32,
      height: 32,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        AppLocalizations.t('Select color'),
        style: themeData.textTheme.titleMedium,
      ),
      subheading: Text(
        AppLocalizations.t('Select color shade'),
        style: themeData.textTheme.titleMedium,
      ),
      wheelSubheading: Text(
        AppLocalizations.t('Selected color and its shades'),
        style: themeData.textTheme.titleMedium,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const flex.ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: themeData.textTheme.bodySmall,
      colorNameTextStyle: themeData.textTheme.bodySmall,
      colorCodeTextStyle: themeData.textTheme.bodyMedium,
      colorCodePrefixStyle: themeData.textTheme.bodySmall,
      selectedPickerTypeColor: themeData.colorScheme.primary,
      pickersEnabled: const <flex.ColorPickerType, bool>{
        flex.ColorPickerType.both: false,
        flex.ColorPickerType.primary: true,
        flex.ColorPickerType.accent: true,
        flex.ColorPickerType.bw: false,
        flex.ColorPickerType.custom: true,
        flex.ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      context,
      actionsPadding: const EdgeInsets.all(16),
      constraints:
          const BoxConstraints(minHeight: 480, minWidth: 300, maxWidth: 320),
    );
  }

  //群主选择界面
  Widget _buildColorPicker(BuildContext context) {
    Widget indicator = flex.ColorIndicator(
      width: 32,
      height: 32,
      borderRadius: 4,
      color: myself.seedColor,
      onSelectFocus: false,
      onSelect: () async {
        Color seedColor = myself.seedColor;
        if (!(await colorPickerDialog())) {
          myself.seedColor = seedColor;
        }
      },
    );
    return Row(children: [
      Text(AppLocalizations.t('Seed color')),
      const Spacer(),
      indicator,
      const SizedBox(
        width: 10,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildColorPicker(context);
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    myself.removeListener(_update);
    super.dispose();
  }
}
