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
        validationMessages: validationMessages,
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

  Widget _buildPinPut(BuildContext context) {
    var name = platformDataField.name;
    var pinputField = ReactivePinPut(
      formControlName: name,
      focusNode: focusNode,
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
      autofocus: platformDataField.autofocus,
      focusNode: focusNode,
      onChanged: (FormControl<T> formControl) {
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
    );
    children.add(radioGroup);

    return Row(children: children);
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
      toggleSwitch
    ]);
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
      onChanged: (FormControl<T> formControl) {
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
    );
    children.add(checkboxGroup);
    return Row(
      children: children,
    );
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
    children.add(chipGroup);
    return Row(
      children: children,
    );
  }

  /// 多个字符串选择一个
  Widget _buildToggleButtons(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];
    var toggleButtons = ReactiveToggleButtons<T>(
      formControlName: name,
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
      toggleButtons,
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
          activeColor: myself.primary,
          inactiveColor: Colors.grey,
        ));
    children.add(switcher);

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(children: children));
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
        padding: const EdgeInsets.all(10.0),
        hint: Text(AppLocalizations.t(platformDataField.hintText ?? '')),
        isDense: true,
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
      type: type,
      decoration: decoration,
      locale: myself.locale,
    );

    return datePicker;
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
      decoration: decoration,
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
      decoration: decoration,
    );

    return colorPicker;
  }

  Widget _buildCountryCodePicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget colorPicker = ReactiveCountryCodePicker(
      formControlName: name,
    );

    return colorPicker;
  }

  Widget _buildFilePicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveFilePicker<String>(
      formControlName: name,
      decoration: decoration,
    );

    return filePicker;
  }

  /// List<SelectedFile>
  Widget _buildImagePicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveImagePicker(
      formControlName: name,
      decoration: decoration,
    );

    return filePicker;
  }

  ///
  Widget _buildTypeAhead(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveTypeAhead<String, String>(
      formControlName: name,
      stringify: (value) => value,
      suggestionsCallback: (pattern) {},
      itemBuilder: (context, city) {
        return Text(city);
      },
      decoration: decoration,
    );

    return filePicker;
  }

  ///
  Widget _buildRawAutocomplete(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    var options = platformDataField.options;
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveRawAutocomplete<String, String>(
      formControlName: name,
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

    return filePicker;
  }

  Widget _buildMonthPicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveMonthPickerDialog(
      formControlName: name,
      decoration: decoration,
    );

    return filePicker;
  }

  Widget _buildSlidingSegmentedControl(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveSlidingSegmentedControl<String, String>(
      formControlName: name,
      decoration: decoration,
      children: {},
    );

    return filePicker;
  }

  Widget _buildCupertinoSwitch(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveCupertinoSwitch<bool>(
      formControlName: name,
    );

    return filePicker;
  }

  Widget _buildSleekCircularSlider(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveSleekCircularSlider<double>(
      formControlName: name,
      decoration: decoration,
      min: 5,
      max: 100,
      heightFactor: 0.78,
    );

    return filePicker;
  }

  Widget _buildSegmentedControl(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveSegmentedControl<String, String>(
      formControlName: name,
      decoration: decoration,
      children: {},
    );

    return filePicker;
  }

  Widget _buildRangeSlider(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveRangeSlider<RangeValues>(
      formControlName: name,
      decoration: decoration,
      min: 0,
      max: 100,
      divisions: 5,
      labelBuilder: (values) => RangeLabels(
        values.start.round().toString(),
        values.end.round().toString(),
      ),
    );

    return filePicker;
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
      validationMessages: validationMessages,
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

  Widget _buildSignature(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveSignature<Uint8List>(
      formControlName: name,
      decoration: decoration,
      height: 200,
      backgroundColor: Colors.grey,
    );

    return filePicker;
  }

  Widget _buildPhoneContactPicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactivePhoneContactPicker<PhoneContact>(
      formControlName: name,
      decoration: decoration,
      contactBuilder: (PhoneContact? contact) {
        return Column(
          children: <Widget>[
            const Text("Phone contact:"),
            Text("Name: ${contact?.fullName}"),
            Text(
                "Phone: ${contact?.phoneNumber!.number} (${contact?.phoneNumber!.label})")
          ],
        );
      },
    );

    return filePicker;
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
        items: items,
      )
    ]);

    return dropdownButton;
  }

  Widget _buildFancyPasswordField(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveFancyPasswordField<String>(
      formControlName: name,
      decoration: decoration,
      validationRules: {
        UppercaseValidationRule(),
        LowercaseValidationRule(),
        DigitValidationRule(),
        SpecialCharacterValidationRule(),
        MinCharactersValidationRule(6),
      },
    );

    return filePicker;
  }

  Widget _buildLanguageToolTextField(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveLanguageToolTextField<String>(
      formControlName: name,
      decoration: decoration,
    );

    return filePicker;
  }

  Widget _buildNativeTextInput(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    Widget filePicker = ReactiveFlutterNativeTextInput<String>(
      formControlName: name,
      decoration: _buildBoxDecoration(),
    );

    return filePicker;
  }

  Widget _buildCartStepper(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveCartStepper<int, int>(
      formControlName: name,
      decoration: decoration,
      stepper: 1,
    );

    return filePicker;
  }

  Widget _buildRatingBar(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveRatingBarBuilder<double>(
      formControlName: name,
      decoration: decoration,
      itemBuilder: (BuildContext context, int index) {
        return const Icon(
          Icons.star,
          color: Colors.amber,
        );
      },
    );

    return filePicker;
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveCupertinoTextField<String>(
      formControlName: name,
    );

    return filePicker;
  }

  Widget _buildFileSelector(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveFileSelector<String>(
      formControlName: name,
    );

    return filePicker;
  }

  Widget _buildDropdownMenu(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveDropdownMenu<String, String>(
      formControlName: 'input',
      dropdownMenuEntries: [],
    );

    return filePicker;
  }

  Widget _buildDropdownButton(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveDropdownButton2<String, String>(
      formControlName: 'input',
    );

    return filePicker;
  }

  Widget _buildCodeTextField(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveCodeTextField<String>(
      formControlName: 'input',
      controller: CodeController(),
    );

    return filePicker;
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
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveSwitchListTile(
      formControlName: 'input',
    );

    return filePicker;
  }

  Widget _buildAnimatedToggleSwitch(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveAnimatedToggleSwitchRolling<int, int>(
      formControlName: name,
      values: [],
    );

    return filePicker;
  }

  Widget _buildDropdownSearch(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveDropdownSearch<String, String>(
      formControlName: 'input',
      dropdownDecoratorProps: DropDownDecoratorProps(
        decoration: decoration,
      ),
    );

    return filePicker;
  }

  Widget _buildInputDecorator(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveInputDecorator(
      formControlName: 'input',
      decoration: decoration,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Expanded(child: Text('Some label')),
          ReactiveCheckbox(formControlName: 'input'),
        ],
      ),
    );

    return filePicker;
  }

  Widget _buildPinCode(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);
    Widget filePicker = ReactiveInputDecorator(
      formControlName: 'input',
      decoration: decoration,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Expanded(child: Text('Some label')),
          ReactiveCheckbox(formControlName: 'input'),
        ],
      ),
    );

    return filePicker;
  }

  Widget _buildLanguagePicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }
    Widget filePicker = ReactiveLanguagePickerDialog<String>(
      formControlName: name,
      valueAccessor: LanguageCodeValueAccessor(),
      builder: (BuildContext context, Language? language,
          Future<Language?> Function() showDialog) {
        return ListTile(
          onTap: showDialog,
          title: Text(language?.name ?? "No language selected"),
        );
      },
    );

    return filePicker;
  }

  Widget _buildWechatAssetsPicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }

    Widget filePicker = ReactiveWechatAssetsPicker<List<AssetEntity>>(
      formControlName: name,
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

    return filePicker;
  }

  Widget _buildWechatCameraPicker(BuildContext context) {
    var name = platformDataField.name;
    Color? value = formGroup.value[name] as Color?;
    if (value == null) {
      formGroup.value[name] = myself.primary;
    }

    Widget filePicker = ReactiveWechatCameraPicker<AssetEntity>(
      formControlName: name,
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

    return filePicker;
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
        validationMessages: validationMessages,
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
        dataFieldWidget = _buildInputDecorator(context);
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
