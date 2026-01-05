import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/checkbox_group.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/chip_group.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/choice.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/country_code.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/radio_group.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/reactive_month_picker_dialog.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/toggle_buttons.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/wechat/selected_asset_view.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget/wechat/selected_assets_list_view.dart';
import 'package:flutter/material.dart';
import 'package:reactive_advanced_switch/reactive_advanced_switch.dart';
import 'package:reactive_cart_stepper/reactive_cart_stepper.dart';
import 'package:reactive_color_picker/reactive_color_picker.dart';
import 'package:reactive_contact_picker/reactive_contact_picker.dart';
import 'package:reactive_cupertino_switch/reactive_cupertino_switch.dart';
import 'package:reactive_date_range_picker/reactive_date_range_picker.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_extended_text_field/reactive_extended_text_field.dart';
import 'package:reactive_fancy_password_field/reactive_fancy_password_field.dart';
import 'package:reactive_file_picker/reactive_file_picker.dart';
import 'package:reactive_flutter_native_text_input/reactive_flutter_native_text_input.dart';
import 'package:reactive_flutter_typeahead/reactive_flutter_typeahead.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_image_picker/reactive_image_picker.dart';
import 'package:reactive_language_picker/reactive_language_picker.dart';
import 'package:reactive_languagetool_textfield/reactive_languagetool_textfield.dart';
import 'package:reactive_multi_select_flutter/reactive_multi_select_flutter.dart';
import 'package:reactive_phone_form_field/reactive_phone_form_field.dart';
import 'package:reactive_pinput/reactive_pinput.dart';
import 'package:reactive_range_slider/reactive_range_slider.dart';
import 'package:reactive_raw_autocomplete/reactive_raw_autocomplete.dart';
import 'package:reactive_segmented_control/reactive_segmented_control.dart';
import 'package:reactive_signature/reactive_signature.dart';
import 'package:reactive_sleek_circular_slider/reactive_sleek_circular_slider.dart';
import 'package:reactive_sliding_segmented/reactive_sliding_segmented.dart';
import 'package:reactive_toggle_switch/reactive_toggle_switch.dart';
import 'package:reactive_wechat_assets_picker/reactive_wechat_assets_picker.dart';
import 'package:reactive_wechat_camera_picker/reactive_wechat_camera_picker.dart';
import 'package:reactive_code_text_field/reactive_code_text_field.dart';
import 'package:reactive_dropdown_search/reactive_dropdown_search.dart';
import 'package:reactive_dropdown_button2/reactive_dropdown_button2.dart';
import 'package:reactive_dropdown_menu/reactive_dropdown_menu.dart';
import 'package:reactive_file_selector/reactive_file_selector.dart';
import 'package:reactive_cupertino_text_field/reactive_cupertino_text_field.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';
import 'package:reactive_input_decorator/reactive_input_decorator.dart';
import 'package:reactive_animated_toggle_switch/reactive_animated_toggle_switch.dart';
import 'package:reactive_pin_code_fields/reactive_pin_code_fields.dart';
import 'package:reactive_fluent_ui/reactive_fluent_ui.dart' as fui;

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class PlatformReactiveDataField<T> extends StatelessWidget {
  final PlatformDataField<T> platformDataField;
  final FormGroup formGroup;
  final FocusNode? focusNode;

  const PlatformReactiveDataField({
    super.key,
    required this.platformDataField,
    required this.formGroup,
    this.focusNode,
  });

  InputDecoration _buildInputDecoration(PlatformDataField platformDataField) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var prefixIcon = platformDataField.prefixIcon;
    var suffixIcon = platformDataField.suffixIcon;
    var prefix = platformDataField.prefix;
    var suffix = platformDataField.suffix;
    var hintText = platformDataField.hintText;
    if (platformDataField.cancel) {
      suffixIcon ??= IconButton(
          //如果文本长度不为空则显示清除按钮
          onPressed: () {
            formGroup.control(name).value = '';
          },
          icon: Icon(
            Icons.cancel,
            color: myself.primary,
          ));
    }
    InputDecoration inputDecoration = buildInputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        prefix: prefix,
        suffixIcon: suffixIcon,
        suffix: suffix,
        hintText: hintText);

    return inputDecoration;
  }

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      border: Border.all(
        color: myself.primary,
      ),
    );
  }

  Map<String, String Function(Object)> _buildValidationMessages(
      Map<String, String Function(Object)>? validationMessages) {
    Map<String, String Function(Object)> messages = {};
    if (validationMessages != null) {
      for (var entry in validationMessages.entries) {
        messages[entry.key] =
            (Object o) => AppLocalizations.t(entry.value.call(o));
      }
    }

    return messages;
  }

  Widget? _buildPrefixWidget() {
    Widget? icon = platformDataField.prefixIcon;
    if (icon == null) {
      final String? avatar = platformDataField.avatar;
      if (avatar != null) {
        icon = ImageUtil.buildImageWidget(imageContent: avatar);
      }
    }

    return icon;
  }

  Widget _buildLabel(BuildContext context) {
    String label = platformDataField.label;
    label = '${AppLocalizations.t(label)}:';
    var name = platformDataField.name;
    final dynamic value = formGroup.control(name).value;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 14.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildPrefixWidget() ?? nilBox,
          const SizedBox(
            width: 10.0,
          ),
          AutoSizeText(label),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
              child: AutoSizeText((value ?? '').toString(),
                  textAlign: TextAlign.start))
        ]));
  }

  Widget _buildTextField(BuildContext context) {
    var name = platformDataField.name;
    var readOnly = platformDataField.readOnly;
    var autofocus = platformDataField.autofocus;
    InputType inputType = platformDataField.inputType;
    TextInputType textInputType =
        platformDataField.textInputType ?? TextInputType.text;
    Map<String, String Function(Object)>? validationMessages =
        platformDataField.validationMessages;

    InputDecoration decoration = _buildInputDecoration(platformDataField);

    return ReactiveTextField<T>(
        formControlName: name,
        decoration: decoration,
        validationMessages: _buildValidationMessages(validationMessages),
        keyboardType: textInputType,
        readOnly: readOnly,
        obscureText: inputType == InputType.password,
        inputFormatters: platformDataField.inputFormatters,
        autofocus: autofocus,
        focusNode: focusNode,
        maxLines:
            inputType == InputType.password ? 1 : platformDataField.maxLines,
        minLines: platformDataField.minLines,
        onChanged: (FormControl<T> formControl) {
          platformDataField.onChanged?.call(formControl.value);
        },
        onEditingComplete: (FormControl<T> formControl) {
          platformDataField.onEditingComplete?.call();
        },
        onSubmitted: (FormControl<T> formControl) {
          platformDataField.onSubmitted?.call(formControl.value);
        });
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget textField = ReactiveCupertinoTextField<String>(
        formControlName: name,
        decoration: _buildBoxDecoration(),
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        keyboardType: platformDataField.textInputType,
        readOnly: platformDataField.readOnly,
        obscureText: platformDataField.inputType == InputType.password,
        inputFormatters: platformDataField.inputFormatters,
        autofocus: platformDataField.autofocus,
        focusNode: focusNode,
        inputDecoration: decoration,
        prefix: platformDataField.prefix,
        suffix: platformDataField.suffix,
        maxLines: platformDataField.inputType == InputType.password
            ? 1
            : platformDataField.maxLines,
        minLines: platformDataField.minLines,
        onEditingComplete: () {
          platformDataField.onEditingComplete?.call();
        },
        onSubmitted: () {
          platformDataField.onSubmitted?.call(formGroup.value[name]);
        });

    return textField;
  }

  Widget _buildExtendedTextField(BuildContext context) {
    var name = platformDataField.name;
    var readOnly = platformDataField.readOnly;
    var autofocus = platformDataField.autofocus;
    InputType inputType = platformDataField.inputType;
    TextInputType textInputType =
        platformDataField.textInputType ?? TextInputType.text;
    Map<String, String Function(Object)>? validationMessages =
        platformDataField.validationMessages;

    InputDecoration decoration = _buildInputDecoration(platformDataField);

    return ReactiveExtendedTextField<String>(
      formControlName: name,
      decoration: decoration,
      validationMessages: _buildValidationMessages(validationMessages),
      keyboardType: textInputType,
      readOnly: readOnly,
      obscureText: inputType == InputType.password,
      inputFormatters: platformDataField.inputFormatters,
      autofocus: autofocus,
      focusNode: focusNode,
      maxLines: platformDataField.maxLines,
      minLines: platformDataField.minLines,
    );
  }

  Widget _buildFancyPasswordField(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget fancyPasswordField = ReactiveFancyPasswordField<String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      validationRules: {
        UppercaseValidationRule(),
        LowercaseValidationRule(),
        DigitValidationRule(),
        SpecialCharacterValidationRule(),
        MinCharactersValidationRule(6),
      },
    );

    return fancyPasswordField;
  }

  Widget _buildNativeTextInput(BuildContext context) {
    var name = platformDataField.name;
    Widget nativeTextInput = ReactiveFlutterNativeTextInput<String>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        decoration: _buildBoxDecoration(),
        maxLines: platformDataField.maxLines ?? 1,
        minLines: platformDataField.minLines ?? 1,
        focusNode: focusNode,
        onChanged: (value) {
          platformDataField.onChanged?.call(value);
        });

    return nativeTextInput;
  }

  Widget _buildFluentTextFormBox(BuildContext context) {
    var name = platformDataField.name;
    Widget fluentTextFormBox = fui.ReactiveFluentTextFormBox<String>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        keyboardType: platformDataField.textInputType,
        readOnly: platformDataField.readOnly,
        obscureText: platformDataField.inputType == InputType.password,
        inputFormatters: platformDataField.inputFormatters,
        autofocus: platformDataField.autofocus,
        prefix: platformDataField.prefix,
        suffix: platformDataField.suffix,
        maxLines: platformDataField.inputType == InputType.password
            ? 1
            : platformDataField.maxLines,
        minLines: platformDataField.minLines,
        onEditingComplete: () {
          platformDataField.onEditingComplete?.call();
        });

    return fluentTextFormBox;
  }

  Widget _buildCodeTextField(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget codeTextField = ReactiveCodeTextField<String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      focusNode: focusNode,
      inputDecoration: decoration,
      keyboardType: platformDataField.textInputType,
      minLines: platformDataField.minLines,
      maxLines: platformDataField.maxLines,
      readOnly: platformDataField.readOnly,
      controller: CodeController(),
    );

    return codeTextField;
  }

  Widget _buildPinPut(BuildContext context) {
    var name = platformDataField.name;
    var pinputField = ReactivePinPut(
      formControlName: name,
      focusNode: focusNode,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      keyboardType: platformDataField.textInputType!,
      readOnly: platformDataField.readOnly,
      inputFormatters: platformDataField.inputFormatters ?? const [],
      onSubmitted: platformDataField.onSubmitted,
      length: platformDataField.length!,
      onCompleted: platformDataField.onChanged,
    );

    return pinputField;
  }

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildRadioGroup(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];
    List<Widget> children = [];
    var prefixIcon = _buildPrefixWidget();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    var radioGroup = ReactiveRadioGroup<T>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      focusNode: focusNode,
      onChanged: (FormControl<T> formControl) {
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
    );
    children.add(Expanded(child: radioGroup));

    return Row(children: children);
  }

  ///多个字符串选择多个，对应的字段是字符串的Set
  Widget _buildCheckboxGroup(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];

    List<Widget> children = [];
    var prefixIcon = _buildPrefixWidget();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    var checkboxGroup = ReactiveCheckboxGroup<T>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      onChanged: (FormControl<T> formControl) {
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
    );
    children.add(Expanded(child: checkboxGroup));
    return Row(
      children: children,
    );
  }

  Widget _buildFluentToggleSwitch(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];

    List<Widget> children = [];
    var prefixIcon = _buildPrefixWidget();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    var fluentToggleSwitch = fui.ReactiveFluentToggleSwitch<bool>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      focusNode: focusNode,
      autofocus: platformDataField.autofocus,
    );
    children.add(Expanded(child: fluentToggleSwitch));
    return Row(
      children: children,
    );
  }

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildToggleSwitch(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];
    List<String> labels = [];
    List<IconData> icons = [];
    for (var i = 0; i < options.length; ++i) {
      var option = options[i];
      if (option.icon != null) {
        icons.add(option.icon!);
      } else {
        labels.add(option.label);
      }
    }

    var toggleSwitch = ReactiveToggleSwitch<T>(
      formControlName: name,
      activeBgColor: [myself.primary],
      activeFgColor: Colors.white,
      inactiveBgColor: myself.secondary,
      inactiveFgColor: Colors.white,
      totalSwitches: options.length,
      labels: labels,
      icons: icons,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
    );
    List<Widget> children = [];
    var prefixIcon = _buildPrefixWidget();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    children.addAll([
      const SizedBox(
        width: 15.0,
      ),
      Expanded(child: toggleSwitch)
    ]);
    return Row(children: children);
  }

  Widget _buildAnimatedToggleSwitch(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<DropdownMenuItem<String>> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuItem<String>(
            value: option.value.toString(), child: Text(option.label));
        items.add(item);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget toggleSwitchRolling = ReactiveAnimatedToggleSwitchRolling<int, int>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      values: [],
    );

    return toggleSwitchRolling;
  }

  /// 多个字符串选择一个
  Widget _buildToggleButtons(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];
    var toggleButtons = ReactiveToggleButtons<T>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      borderRadius: borderRadius,
      fillColor: myself.primary,
      selectedColor: Colors.white,
      onToggle: (FormControl<T> formControl) {
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
    );

    List<Widget> children = [];
    var prefixIcon = _buildPrefixWidget();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    children.addAll([
      const SizedBox(
        width: 15,
      ),
      Expanded(child: toggleButtons),
    ]);
    var row = Row(
      children: children,
    );

    return row;
  }

  /// 适合数据类型为bool
  Widget _buildSwitch(BuildContext context) {
    var name = platformDataField.name;
    List<Widget> children = [];
    var prefixIcon = platformDataField.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = platformDataField.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    var switcher = Transform.scale(
        scale: 0.8,
        child: ReactiveSwitch(
          formControlName: name,
          focusNode: focusNode,
          activeColor: myself.primary,
          activeTrackColor: Colors.white,
          inactiveThumbColor: myself.secondary,
          inactiveTrackColor: Colors.grey,
          onChanged: (FormControl<bool> formControl) {
            bool? value = formControl.value;
            platformDataField.onChanged?.call(value);
          },
        ));
    children.add(switcher);

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(children: children));
  }

  /// 适合数据类型为bool
  Widget _buildAdvancedSwitch(BuildContext context) {
    var name = platformDataField.name;
    List<Widget> children = [];
    var prefixIcon = platformDataField.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = platformDataField.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    var switcher = Transform.scale(
        scale: 0.8,
        child: ReactiveAdvancedSwitch<bool>(
          formControlName: name,
          decoration: decoration,
          validationMessages:
              _buildValidationMessages(platformDataField.validationMessages),
          activeColor: myself.primary,
          inactiveColor: Colors.grey,
        ));
    children.add(switcher);

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(children: children));
  }

  /// CupertinoSlidingSegmentedControl
  Widget _buildSlidingSegmentedControl(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options ?? [];
    Map<String, Widget> children = {};
    for (var i = 0; i < options.length; ++i) {
      var option = options[i];
      if (option.icon != null) {
        children[option.label] = Icon(option.icon!);
      } else {
        children[option.label] = Text(option.label);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget slidingSegmentedControl =
        ReactiveSlidingSegmentedControl<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      children: children,
    );

    return slidingSegmentedControl;
  }

  /// FluentSlider
  Widget _buildFluentSlider(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget fluentSlider = fui.ReactiveFluentSlider<double>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      min: platformDataField.params?['min'],
      max: platformDataField.params?['max'],
    );

    return fluentSlider;
  }

  Widget _buildCupertinoSwitch(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget cupertinoSwitch = ReactiveCupertinoSwitch<bool>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      focusNode: focusNode,
      autofocus: platformDataField.autofocus,
      activeTrackColor: myself.primary,
      inactiveTrackColor: Colors.grey,
    );

    return cupertinoSwitch;
  }

  Widget _buildSleekCircularSlider(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget sleekCircularSlider = ReactiveSleekCircularSlider<double>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        decoration: decoration,
        min: platformDataField.params?['min'],
        max: platformDataField.params?['max'],
        heightFactor: platformDataField.params?['heightFactor'],
        widthFactor: platformDataField.params?['widthFactor'],
        onChange: (value) {});

    return sleekCircularSlider;
  }

  /// CupertinoSegmentedControl，分段控制，类似单选框
  Widget _buildSegmentedControl(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options ?? [];
    Map<String, Widget> children = {};
    for (var i = 0; i < options.length; ++i) {
      var option = options[i];
      if (option.icon != null) {
        children[option.label] = Icon(option.icon!);
      } else {
        children[option.label] = Text(option.label);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget segmentedControl = ReactiveSegmentedControl<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      unselectedColor: Colors.grey,
      selectedColor: myself.primary,
      borderColor: myself.primary,
      children: children,
    );

    return segmentedControl;
  }

  Widget _buildRangeSlider(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget rangeSlider = ReactiveRangeSlider<RangeValues>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        decoration: decoration,
        min: platformDataField.params?['min'],
        max: platformDataField.params?['max'],
        divisions: platformDataField.params?['divisions'],
        activeColor: myself.primary,
        inactiveColor: Colors.grey,
        labelBuilder: (values) => RangeLabels(
              values.start.round().toString(),
              values.end.round().toString(),
            ),
        onChanged: (value) {});

    return rangeSlider;
  }

  //多个字符串选择多个，对应的字段是字符串的Set
  Widget _buildChipGroup(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];

    List<Widget> children = [];
    var prefixIcon = _buildPrefixWidget();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    var chipGroup = ReactiveChipGroup<T>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      onSelected: (FormControl<T> formControl) {
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
      disabledColor: Colors.white,
      selectedColor: myself.primary,
      backgroundColor: Colors.white,
      showCheckmark: false,
      checkmarkColor: myself.primary,
    );
    children.add(Expanded(child: chipGroup));
    return Row(
      children: children,
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<DropdownMenuItem<T>> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuItem<T>(
          value: option.value,
          child: Text(
            AppLocalizations.t(option.label),
            style: const TextStyle(color: Colors.black),
          ),
        );
        children.add(item);
      }
    }
    var dropdownButton = Row(children: [
      Text(AppLocalizations.t(platformDataField.label)),
      const SizedBox(
        width: 15.0,
      ),
      ReactiveDropdownField<T>(
        formControlName: name,
        dropdownColor: myself.primary,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        decoration: _buildInputDecoration(platformDataField),
        padding: const EdgeInsets.all(10.0),
        hint: Text(AppLocalizations.t(platformDataField.hintText ?? '')),
        isDense: true,
        readOnly: platformDataField.readOnly,
        items: children,
        onChanged: (FormControl<T> formControl) {
          var value = formControl.value;
          platformDataField.onChanged?.call(value);
        },
      )
    ]);

    return dropdownButton;
  }

  Widget _buildChoice(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    var dropdownButton = Row(children: [
      Text(AppLocalizations.t(platformDataField.label)),
      const SizedBox(
        width: 15.0,
      ),
      ReactiveChoice<T>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        itemType: ItemType.chip,
        title: AppLocalizations.t(platformDataField.label),
        options: options!,
        onChanged: (FormControl<Set<T>> formControl) {
          Set<T>? value = formControl.value;
          platformDataField.onChanged?.call(value);
        },
      )
    ]);

    return dropdownButton;
  }

  Widget _buildDateTimePicker(BuildContext context) {
    var name = platformDataField.name;
    List<Widget> children = [];
    var prefixIcon = platformDataField.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = platformDataField.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    DataType dataType = platformDataField.dataType;
    ReactiveDatePickerFieldType type = ReactiveDatePickerFieldType.date;
    if (dataType == DataType.date) {
      type = ReactiveDatePickerFieldType.date;
    } else if (dataType == DataType.time) {
      type = ReactiveDatePickerFieldType.time;
    } else if (dataType == DataType.datetime) {
      type = ReactiveDatePickerFieldType.dateTime;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget datePicker = ReactiveDateTimePicker(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        type: type,
        showClearIcon: platformDataField.cancel,
        decoration: decoration,
        locale: myself.locale,
        keyboardType: platformDataField.textInputType);

    return datePicker;
  }

  Widget _buildFluentDatePicker(BuildContext context) {
    var name = platformDataField.name;
    List<Widget> children = [];
    var prefixIcon = platformDataField.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = platformDataField.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget datePicker = fui.ReactiveFluentDatePicker<DateTime>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        focusNode: focusNode,
        autofocus: platformDataField.autofocus,
        locale: myself.locale);

    return datePicker;
  }

  Widget _buildFluentTimePicker(BuildContext context) {
    var name = platformDataField.name;
    List<Widget> children = [];
    var prefixIcon = platformDataField.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = platformDataField.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget timePicker = fui.ReactiveFluentTimePicker<DateTime>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      locale: myself.locale,
    );

    return timePicker;
  }

  /// 返回值是DateTimeRange
  Widget _buildDateRangePicker(BuildContext context) {
    var name = platformDataField.name;
    List<Widget> children = [];
    var prefixIcon = platformDataField.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = platformDataField.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }

    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget datePicker = ReactiveDateRangePicker(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      showClearIcon: platformDataField.cancel,
      locale: myself.locale,
    );

    return datePicker;
  }

  Widget _buildColorPicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget colorPicker = ReactiveColorPicker<Color>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
    );

    return colorPicker;
  }

  Widget _buildCountryCodePicker(BuildContext context) {
    var name = platformDataField.name;
    Object? value = formGroup.value[name];
    if (value == null) {
      formGroup.value[name] = myself.locale.countryCode;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget countryCodePicker = ReactiveCountryCodePicker(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        searchDecoration: decoration,
        onChanged: (value) {
          platformDataField.onChanged?.call(value.value);
        });

    return countryCodePicker;
  }

  Widget _buildFilePicker(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveFilePicker<String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
    );

    return filePicker;
  }

  /// List<SelectedFile>
  Widget _buildImagePicker(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget imagePicker = ReactiveImagePicker(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
    );

    return imagePicker;
  }

  ///
  Widget _buildTypeAhead(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget typeAhead = ReactiveTypeAhead<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      stringify: (value) => value,
      suggestionsCallback: (pattern) {
        return null;
      },
      itemBuilder: (context, city) {
        return Text(city);
      },
      focusNode: focusNode,
      readOnly: platformDataField.readOnly,
      decoration: decoration,
    );

    return typeAhead;
  }

  ///
  Widget _buildRawAutocomplete(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget rawAutocomplete = ReactiveRawAutocomplete<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      optionsBuilder: (TextEditingValue textEditingValue) {
        List<String> values = [];
        for (var option in options!) {
          if (option.label.contains(textEditingValue.text.toLowerCase())) {
            values.add(option.label);
          }
        }
        return values;
      },
      autocompleteOnSubmit: true,
      optionsViewBuilder: (BuildContext context,
          void Function(String) onSelected, Iterable<String> options) {
        final selectedIndex = AutocompleteHighlightedOption.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200.0,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(option),
                      selected: selectedIndex == index,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return rawAutocomplete;
  }

  Widget _buildFluentAutoSuggestBox(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<fui.AutoSuggestBoxItem<String>> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = fui.AutoSuggestBoxItem<String>(
            value: option.value.toString(), label: option.label);
        items.add(item);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget fluentAutoSuggestBox =
        fui.ReactiveFluentAutoSuggestBox<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      inputFormatters: platformDataField.inputFormatters,
      items: items,
    );

    return fluentAutoSuggestBox;
  }

  Widget _buildFluentComboBox(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<fui.ComboBoxItem<String>> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = fui.ComboBoxItem<String>(
          value: option.value.toString(),
          child: Text(option.label),
        );
        items.add(item);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget fluentComboBox = fui.ReactiveFluentComboBox<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      focusNode: focusNode,
      items: items,
    );

    return fluentComboBox;
  }

  Widget _buildMonthPicker(BuildContext context) {
    var name = platformDataField.name;
    Object? value = formGroup.value[name];
    if (value == null) {
      formGroup.value[name] = DateTime.now().month;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveMonthPickerDialog(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      locale: myself.locale,
      showClearIcon: platformDataField.cancel,
    );

    return filePicker;
  }

  Widget _buildSignature(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget signature = ReactiveSignature<Uint8List>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      height: 200,
      backgroundColor: Colors.grey,
    );

    return signature;
  }

  Widget _buildPhoneContactPicker(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget phoneContactPicker = ReactivePhoneContactPicker<PhoneContact>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      contactBuilder: (PhoneContact? contact) {
        return Column(
          children: <Widget>[
            Text(AppLocalizations.t('Phone contact')),
            Text('${AppLocalizations.t('Name')}: ${contact?.fullName}'),
            Text(
                '${AppLocalizations.t('Name')}: ${contact?.phoneNumber!.number} (${contact?.phoneNumber!.label})')
          ],
        );
      },
    );

    return phoneContactPicker;
  }

  Widget _buildMultiSelectDialogField(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<MultiSelectItem<String>> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item =
            MultiSelectItem<String>(option.value.toString(), option.label);
        items.add(item);
      }
    }
    var dropdownButton = Row(children: [
      Text(AppLocalizations.t(platformDataField.label)),
      const SizedBox(
        width: 15.0,
      ),
      // ReactiveMultiSelectChipField
      ReactiveMultiSelectDialogField<String, String>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        items: items,
        inputDecoration: _buildInputDecoration(platformDataField),
        onSelectionChanged: (value) {},
      )
    ]);

    return dropdownButton;
  }

  Widget _buildLanguageToolTextField(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget languageToolTextField = ReactiveLanguageToolTextField<String>(
        formControlName: name,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        decoration: decoration,
        keyboardType: platformDataField.textInputType,
        autofocus: platformDataField.autofocus,
        readOnly: platformDataField.readOnly,
        maxLines: platformDataField.maxLines,
        minLines: platformDataField.minLines,
        focusNode: focusNode,
        onSubmitted: () {});

    return languageToolTextField;
  }

  Widget _buildCartStepper(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget cartStepper = ReactiveCartStepper<int, int>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      stepper: platformDataField.params?['stepper'] ?? 1,
    );

    return cartStepper;
  }

  Widget _buildRatingBar(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget ratingBar = ReactiveRatingBarBuilder<double>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      decoration: decoration,
      itemBuilder: (BuildContext context, int index) {
        return Icon(
          Icons.star,
          color: myself.primary,
        );
      },
    );

    return ratingBar;
  }

  Widget _buildFileSelector(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget fileSelector = ReactiveFileSelector<String>(
      formControlName: name,
      decoration: decoration,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      allowMultiple: platformDataField.params?['allowMultiple'],
    );

    return fileSelector;
  }

  Widget _buildDropdownMenu(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<DropdownMenuEntry<String>> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuEntry<String>(
            value: option.value.toString(), label: option.label);
        items.add(item);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget dropdownMenu = ReactiveDropdownMenu<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      focusNode: focusNode,
      inputFormatters: platformDataField.inputFormatters,
      dropdownMenuEntries: items,
    );

    return dropdownMenu;
  }

  Widget _buildDropdownButton(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<DropdownMenuItem<String>> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuItem<String>(
            value: option.value.toString(), child: Text(option.label));
        items.add(item);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget dropdownButton = ReactiveDropdownButton2<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      focusNode: focusNode,
      inputDecoration: decoration,
      items: items,
    );

    return dropdownButton;
  }

  Widget _buildCheckboxListTile(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveCheckboxListTile(
      formControlName: 'input',
    );

    return filePicker;
  }

  Widget _buildRadioListTile(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveRadioListTile(
      formControlName: 'input',
      value: null,
    );

    return filePicker;
  }

  Widget _buildSwitchListTile(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget switchListTile = ReactiveSwitchListTile(
      formControlName: 'input',
    );

    return switchListTile;
  }

  Widget _buildDropdownSearch(BuildContext context) {
    var name = platformDataField.name;
    var options = platformDataField.options;
    List<String> items = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        items.add(option.label);
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget dropdownSearch = ReactiveDropdownSearch<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      dropdownDecoratorProps: DropDownDecoratorProps(
        decoration: decoration,
      ),
      items: (_, __) => items,
    );
    ReactiveDropdownSearchMultiSelection<String, String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      dropdownDecoratorProps: DropDownDecoratorProps(
        decoration: decoration,
      ),
      items: (_, __) => items,
    );

    return dropdownSearch;
  }

  /// 对子组件设置外观
  Widget _buildInputDecorator(BuildContext context, Widget child) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget inputDecorator = ReactiveInputDecorator(
        formControlName: name,
        decoration: decoration,
        validationMessages:
            _buildValidationMessages(platformDataField.validationMessages),
        child: child);

    return inputDecorator;
  }

  Widget _buildPinCode(BuildContext context) {
    var name = platformDataField.name;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget pinCodeTextField = ReactivePinCodeTextField(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      autofocus: platformDataField.autofocus,
      focusNode: focusNode,
      readOnly: platformDataField.readOnly,
      length: platformDataField.length!,
      onCompleted: (value) {},
      onSubmitted: (value) {},
    );

    return pinCodeTextField;
  }

  Widget _buildLanguagePicker(BuildContext context) {
    var name = platformDataField.name;
    Language? value = formGroup.value[name] as Language?;
    if (value == null) {
      formGroup.value[name] = Language.fromIsoCode(myself.locale.languageCode);
    }
    Widget languagePicker = ReactiveLanguagePickerDialog<String>(
      formControlName: name,
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      valueAccessor: LanguageCodeValueAccessor(),
      focusNode: focusNode,
      title: Text(platformDataField.label),
      searchInputDecoration: _buildInputDecoration(platformDataField),
      builder: (BuildContext context, Language? language,
          Future<Language?> Function() showDialog) {
        return ListTile(
          onTap: showDialog,
          title: Text(
              AppLocalizations.t(language?.name ?? 'No language selected')),
        );
      },
      onValuePicked: (value) {
        platformDataField.onChanged?.call(value);
      },
    );

    return languagePicker;
  }

  Widget _buildWechatAssetsPicker(BuildContext context) {
    var name = platformDataField.name;
    Widget wechatAssetsPicker = ReactiveWechatAssetsPicker<List<AssetEntity>>(
      formControlName: name,
      decoration: _buildInputDecoration(platformDataField),
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      imagePickerBuilder: (Future<void> Function() pick,
          List<AssetEntity> images, void Function(List<AssetEntity>) onChange) {
        return Column(
          children: [
            SelectedAssetsListView(
              assets: images,
              isDisplayingDetail: ValueNotifier(true),
              onResult: (assets) {},
              onRemoveAsset: (int index) {
                images.removeAt(index);
              },
            ),
            ElevatedButton(
              onPressed: pick,
              child: Text(AppLocalizations.t('Pick')),
            ),
          ],
        );
      },
    );

    return wechatAssetsPicker;
  }

  Widget _buildWechatCameraPicker(BuildContext context) {
    var name = platformDataField.name;
    Widget wechatCameraPicker = ReactiveWechatCameraPicker<AssetEntity>(
      formControlName: name,
      decoration: _buildInputDecoration(platformDataField),
      validationMessages:
          _buildValidationMessages(platformDataField.validationMessages),
      locale: myself.locale,
      imagePickerBuilder: (pick, image, _) {
        return Column(
          children: [
            if (image != null)
              SelectedAssetView(
                asset: image,
                isDisplayingDetail: ValueNotifier(true),
                onRemoveAsset: () {},
              ),
            ElevatedButton(
              onPressed: pick,
              child: Text(AppLocalizations.t('Pick')),
            ),
          ],
        );
      },
    );

    return wechatCameraPicker;
  }

  Widget _buildPhoneFormField(BuildContext context) {
    var name = platformDataField.name;
    var autofocus = platformDataField.autofocus;
    InputType inputType = platformDataField.inputType;
    TextInputType textInputType =
        platformDataField.textInputType ?? TextInputType.text;
    Map<String, String Function(Object)>? validationMessages =
        platformDataField.validationMessages;

    InputDecoration decoration = _buildInputDecoration(platformDataField);

    return ReactivePhoneFormField<String>(
        formControlName: name,
        decoration: decoration,
        validationMessages: _buildValidationMessages(validationMessages),
        keyboardType: textInputType,
        obscureText: inputType == InputType.password,
        inputFormatters: platformDataField.inputFormatters,
        autofocus: autofocus,
        focusNode: focusNode,
        countrySelectorNavigator:
            const CountrySelectorNavigator.modalBottomSheet(),
        onChanged: (FormControl<String> formControl) {
          platformDataField.onChanged?.call(formControl.value);
        },
        onEditingComplete: () {
          platformDataField.onEditingComplete?.call();
        },
        onSubmitted: () {
          platformDataField.onSubmitted?.call(formGroup.value[name]);
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget? dataFieldWidget;

    var inputType = platformDataField.inputType;
    switch (inputType) {
      case InputType.label:
        dataFieldWidget = _buildLabel(context);
        break;
      case InputType.text:
        dataFieldWidget = _buildTextField(context);
        break;
      case InputType.textarea:
        dataFieldWidget = _buildTextField(context);
        break;
      case InputType.password:
        dataFieldWidget = _buildTextField(context);
        break;
      case InputType.pinPut:
        dataFieldWidget = _buildPinPut(context);
        break;
      case InputType.toggleButtons:
        dataFieldWidget = _buildToggleButtons(context);
        break;
      case InputType.checkbox:
        dataFieldWidget = _buildCheckboxGroup(context);
        break;
      case InputType.radio:
        dataFieldWidget = _buildRadioGroup(context);
        break;
      case InputType.dropdownField:
        dataFieldWidget = _buildDropdownField(context);
        break;
      case InputType.toggle:
        dataFieldWidget = _buildToggleSwitch(context);
        break;
      case InputType.toggleSwitch:
        dataFieldWidget = _buildToggleSwitch(context);
        break;
      case InputType.switcher:
        dataFieldWidget = _buildSwitch(context);
        break;
      case InputType.date:
        dataFieldWidget = _buildDateTimePicker(context);
        break;
      case InputType.time:
        dataFieldWidget = _buildDateTimePicker(context);
        break;
      case InputType.datetime:
        dataFieldWidget = _buildDateTimePicker(context);
        break;
      case InputType.color:
        dataFieldWidget = _buildColorPicker(context);
        break;
      case InputType.dateRange:
        dataFieldWidget = _buildDateRangePicker(context);
        break;
      case InputType.calendar:
        dataFieldWidget = _buildDateTimePicker(context);
        break;
      case InputType.custom:
        dataFieldWidget = platformDataField.customWidget!;
        break;
      case InputType.advancedSwitcher:
        dataFieldWidget = _buildAdvancedSwitch(context);
        break;
      case InputType.dropdownSearch:
        dataFieldWidget = _buildDropdownSearch(context);
        break;
      case InputType.file:
        dataFieldWidget = _buildFilePicker(context);
        break;
      case InputType.image:
        dataFieldWidget = _buildImagePicker(context);
        break;
      case InputType.multiImage:
        dataFieldWidget = _buildImagePicker(context);
        break;
      case InputType.segmentedControl:
        dataFieldWidget = _buildSegmentedControl(context);
        break;
      case InputType.signature:
        dataFieldWidget = _buildSignature(context);
        break;
      case InputType.rangeSlider:
        dataFieldWidget = _buildRangeSlider(context);
        break;
      case InputType.circularSlider:
        dataFieldWidget = _buildSleekCircularSlider(context);
        break;
      case InputType.cupertinoTextField:
        dataFieldWidget = _buildCupertinoTextField(context);
        break;
      case InputType.ratingBar:
        dataFieldWidget = _buildRatingBar(context);
        break;
      case InputType.macosUi:
        dataFieldWidget = _buildColorPicker(context);
        break;
      case InputType.cupertinoSwitch:
        dataFieldWidget = _buildCupertinoSwitch(context);
        break;
      case InputType.pinCode:
        dataFieldWidget = _buildPinCode(context);
        break;
      case InputType.cupertinoSlidingSegmentedControl:
        dataFieldWidget = _buildSlidingSegmentedControl(context);
        break;
      case InputType.cupertinoSlider:
        dataFieldWidget = _buildSlidingSegmentedControl(context);
        break;
      case InputType.month:
        dataFieldWidget = _buildMonthPicker(context);
        break;
      case InputType.rawAutocomplete:
        dataFieldWidget = _buildRawAutocomplete(context);
        break;
      case InputType.typeahead:
        dataFieldWidget = _buildTypeAhead(context);
        break;
      case InputType.pinInput:
        dataFieldWidget = _buildPinPut(context);
        break;
      case InputType.directSelect:
        dataFieldWidget = _buildMultiSelectDialogField(context);
        break;
      case InputType.code:
        dataFieldWidget = _buildCodeTextField(context);
        break;
      case InputType.phone:
        dataFieldWidget = _buildPhoneFormField(context);
        break;
      case InputType.extendedText:
        dataFieldWidget = _buildExtendedTextField(context);
        break;
      case InputType.checkboxListTile:
        dataFieldWidget = _buildCheckboxListTile(context);
        break;
      case InputType.contact:
        dataFieldWidget = _buildPhoneContactPicker(context);
        break;
      case InputType.animatedToggleSwitch:
        dataFieldWidget = _buildAnimatedToggleSwitch(context);
        break;
      case InputType.choice:
        dataFieldWidget = _buildChoice(context);
        break;
      case InputType.cartStepper:
        dataFieldWidget = _buildCartStepper(context);
        break;
      case InputType.dropdownButton:
        dataFieldWidget = _buildDropdownField(context);
        break;
      case InputType.dropdownMenu:
        dataFieldWidget = _buildDropdownMenu(context);
        break;
      case InputType.fileSelector:
        dataFieldWidget = _buildFileSelector(context);
        break;
      case InputType.fancyPassword:
        dataFieldWidget = _buildFancyPasswordField(context);
        break;
      case InputType.fluentUi:
        dataFieldWidget = _buildColorPicker(context);
        break;
      case InputType.language:
        dataFieldWidget = _buildLanguagePicker(context);
        break;
      case InputType.inputDecorator:
        dataFieldWidget = _buildInputDecorator(context, Container());
        break;
      case InputType.languagetool:
        dataFieldWidget = _buildLanguageToolTextField(context);
        break;
      case InputType.multiSelect:
        dataFieldWidget = _buildMultiSelectDialogField(context);
        break;
      case InputType.signaturePad:
        dataFieldWidget = _buildSignature(context);
        break;
      case InputType.assets:
        dataFieldWidget = _buildWechatAssetsPicker(context);
        break;
      case InputType.camera:
        dataFieldWidget = _buildWechatCameraPicker(context);
        break;
      case InputType.chip:
        dataFieldWidget = _buildChipGroup(context);
        break;
      case InputType.country:
        dataFieldWidget = _buildCountryCodePicker(context);
        break;
    }

    return dataFieldWidget ?? _buildTextField(context);
  }
}
