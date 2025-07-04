import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/reactive_data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:reactive_color_picker/reactive_color_picker.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_pinput/reactive_pinput.dart';

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
    var label = platformDataField.label;
    var prefixIcon = platformDataField.prefixIcon;
    var suffixIcon = platformDataField.suffixIcon;
    var prefix = platformDataField.prefix;
    var suffix = platformDataField.suffix;
    var hintText = platformDataField.hintText;
    InputDecoration inputDecoration = buildInputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        prefix: prefix,
        suffixIcon: suffixIcon,
        suffix: suffix,
        hintText: hintText);

    return inputDecoration;
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
          CommonAutoSizeText(label),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
              child: CommonAutoSizeText((value ?? '').toString(),
                  textAlign: TextAlign.start))
        ]));
  }

  Widget _buildTextFormField(BuildContext context) {
    var name = platformDataField.name;
    var suffixIcon = platformDataField.suffixIcon;
    var readOnly = platformDataField.readOnly;
    var autofocus = platformDataField.autofocus;
    InputType inputType = platformDataField.inputType;
    TextInputType textInputType =
        platformDataField.textInputType ?? TextInputType.text;
    Map<String, String Function(Object)>? validationMessages =
        platformDataField.validationMessages;
    Widget? suffix;
    if (platformDataField.cancel) {
      suffix = IconButton(
          //如果文本长度不为空则显示清除按钮
          onPressed: () {
            formGroup.control(name).value = '';
          },
          icon: Icon(
            Icons.cancel,
            color: myself.primary,
          ));

      if (suffixIcon == null) {
        suffixIcon = suffix;
        suffix = null;
      }
    }
    InputDecoration decoration = _buildInputDecoration(platformDataField);

    return ReactiveTextField<String>(
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
        onChanged: (FormControl<String> formControl) {
          platformDataField.onChanged?.call(formControl.value);
        },
        onEditingComplete: (FormControl<String> formControl) {
          platformDataField.onEditingComplete?.call();
        },
        onSubmitted: (FormControl<String> formControl) {
          platformDataField.onFieldSubmitted?.call(formControl.value);
        });
  }

  Widget _buildPinput(BuildContext context) {
    var name = platformDataField.name;
    var pinputField = ReactivePinPut(
      formControlName: name,
      focusNode: focusNode,
      autofocus: platformDataField.autofocus,
      keyboardType: platformDataField.textInputType!,
      readOnly: platformDataField.readOnly,
      inputFormatters: platformDataField.inputFormatters ?? const [],
      onSubmitted: platformDataField.onFieldSubmitted,
      length: platformDataField.length!,
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
        if (platformDataField.readOnly) {
          return;
        }
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
      initValue: platformDataField.initValue,
    );
    children.add(radioGroup);

    return Row(children: children);
  }

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildToggleSwitch(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    var options = platformDataField.options ?? [];

    var toggleSwitch = ReactiveToggleSwitch<T>(
      formControlName: name,
      activeBgColor: [myself.primary],
      activeFgColor: Colors.white,
      inactiveBgColor: myself.secondary,
      inactiveFgColor: Colors.white,
      totalSwitches: options.length,
      onToggle: (FormControl<T> formControl) {
        if (platformDataField.readOnly) {
          return;
        }
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
      initValue: platformDataField.initValue,
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
        if (platformDataField.readOnly) {
          return;
        }
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
      initValue: platformDataField.initValue,
    );
    children.add(checkboxGroup);
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
        if (platformDataField.readOnly) {
          return;
        }
        platformDataField.onChanged?.call(formControl.value);
      },
      options: options,
      initValue: platformDataField.initValue,
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
            if (platformDataField.readOnly) {
              return;
            }
            bool? value = formControl.value;
            platformDataField.onChanged?.call(value);
          },
        ));
    children.add(switcher);

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(children: children));
  }

  Widget _buildDropdownButton(BuildContext context) {
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

  Widget _buildDateTimePicker(BuildContext context) {
    var name = platformDataField.name;
    Widget datePicker = ReactiveDateTimePicker(
      formControlName: name,
      type: ReactiveDatePickerFieldType.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 356)),
    );

    return datePicker;
  }

  Widget _buildColorPicker(BuildContext context) {
    var name = platformDataField.name;
    var label = platformDataField.label;
    Color? value = formGroup.value[name] as Color?;
    value ??= platformDataField.initValue;
    value ??= myself.primary;
    formGroup.value[name] = value;
    Widget colorPicker = ReactiveColorPicker<Color>(
      formControlName: name,
    );

    return colorPicker;
  }

  @override
  Widget build(BuildContext context) {
    Widget dataFieldWidget;
    var customWidget = platformDataField.customWidget;
    if (customWidget != null) {
      dataFieldWidget = customWidget;
      return dataFieldWidget;
    }
    var inputType = platformDataField.inputType;
    switch (inputType) {
      case InputType.label:
        dataFieldWidget = _buildLabel(context);
        break;
      case InputType.text:
        dataFieldWidget = _buildTextFormField(context);
        break;
      case InputType.textarea:
        dataFieldWidget = _buildTextFormField(context);
        break;
      case InputType.password:
        dataFieldWidget = _buildTextFormField(context);
        break;
      case InputType.pinput:
        dataFieldWidget = _buildPinput(context);
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
      case InputType.select:
        dataFieldWidget = _buildDropdownButton(context);
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
      default:
        dataFieldWidget = _buildTextFormField(context);
    }
    return dataFieldWidget;
  }
}
