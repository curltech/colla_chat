import 'package:colla_chat/constant/brightness.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
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
    List<S2Choice<String>>? brightnessChoices = [];
    for (var brightnessOption in brightnessOptions) {
      S2Choice<String> item = S2Choice<String>(
          value: brightnessOption.value, title: brightnessOption.label);
      brightnessChoices.add(item);
    }
    return SmartSelect<String>.single(
      title: AppLocalizations.t('Brightness'),
      placeholder: AppLocalizations.t('Select one brightness'),
      selectedValue: appDataProvider.locale,
      onChange: (selected) {
        String value = selected.value;
        appDataProvider.brightness = value;
      },
      choiceItems: brightnessChoices,
      modalType: S2ModalType.bottomSheet,
      modalConfig: S2ModalConfig(
        type: S2ModalType.bottomSheet,
        useFilter: false,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: appDataProvider.themeData.colorScheme.primary,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        //titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
      ),
      tileBuilder: (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSelectWidget(context);
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
