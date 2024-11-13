import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flex_color_picker/flex_color_picker.dart' as flex;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ColorPicker extends StatelessWidget {
  String label;
  Rx<Color> color = Rx<Color>(myself.primaryColor);
  Function(Color color)? onColorChanged;

  ColorPicker(
      {super.key, this.onColorChanged, required this.label, Color? initColor}) {
    if (initColor != null) {
      color.value = initColor;
    }
  }

  Future<bool> colorPickerDialog(BuildContext context) async {
    ThemeData themeData = myself.themeData;
    return flex.ColorPicker(
      color: color.value,
      onColorChanged: (Color color) {
        this.color.value = color;
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

  //颜色选择界面
  Widget _buildColorPicker(BuildContext context) {
    return Obx(
      () {
        Widget indicator = flex.ColorIndicator(
          width: 32,
          height: 32,
          borderRadius: 4,
          color: color.value,
          onSelectFocus: false,
          onSelect: () async {
            var ok = await colorPickerDialog(context);
            if (ok) {
              onColorChanged?.call(color.value);
            }
          },
        );
        return Row(children: [
          Text(AppLocalizations.t(label)),
          const Spacer(),
          indicator,
          const SizedBox(
            width: 10,
          ),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildColorPicker(context);
  }
}
