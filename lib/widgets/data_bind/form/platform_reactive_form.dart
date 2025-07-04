import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_data_field.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:reactive_forms/reactive_forms.dart';

class PlatformReactiveFormController {
  final List<PlatformDataField> dataFields;
  late final FormGroup formGroup;
  final Map<String, FocusNode> focusNodes = {};
  late final KeyboardActionsConfig keyboardActionsConfig;

  PlatformReactiveFormController(this.dataFields) {
    _init();
  }

  _init() {
    Map<String, FormControl> formControls = {};
    final List<KeyboardActionsItem> actions = [];
    for (var i = 0; i < dataFields.length; i++) {
      PlatformDataField platformDataField = dataFields[i];
      var name = platformDataField.name;
      var initValue = platformDataField.initValue;
      var validators = platformDataField.validators ?? const [];
      FormControl formControl;
      var dataType = platformDataField.dataType;
      switch (dataType) {
        case DataType.int:
          formControl = FormControl<int>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.num:
          formControl = FormControl<num>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.bool:
          formControl = FormControl<bool>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.double:
          formControl = FormControl<double>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.date:
          formControl = FormControl<DateTime>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.list:
          formControl = FormControl<List>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.map:
          formControl = FormControl<Map>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.set:
          formControl = FormControl<Set>(
            value: initValue,
            validators: validators,
          );
          break;
        default:
          formControl = FormControl<String>(
            value: initValue,
            validators: validators,
          );
          break;
      }

      var inputType = platformDataField.inputType;
      if (inputType == InputType.text ||
          inputType == InputType.password ||
          inputType == InputType.textarea) {
        var focusNode = FocusNode();
        focusNodes[name] = focusNode;
        KeyboardActionsItem action = KeyboardActionsItem(
          focusNode: focusNode,
          displayActionBar: false,
          displayArrows: false,
          displayDoneButton: false,
        );
        actions.add(action);
      }

      formControls[name] = formControl;
    }
    formGroup = FormGroup(formControls);
    keyboardActionsConfig = KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: myself.primary,
      nextFocus: false,
      actions: actions,
    );
  }

  Map<String, Object?> get values {
    return formGroup.value;
  }

  set values(Map<String, Object?>? values) {
    formGroup.value = values;
  }

  dynamic getValue(String name) {
    return formGroup.control(name).value;
  }

  setValue(String name, dynamic value) {
    formGroup.control(name).value = value;
  }

  reset({Map<String, Object?>? values}) {
    return formGroup.reset(value: values);
  }

  focus(String name) {
    return formGroup.control(name).focus();
  }

  unfocus(String name) {
    return formGroup.control(name).unfocus();
  }

  markAsDisabled(String name) {
    return formGroup.control(name).markAsDisabled();
  }

  markAsTouched(String name) {
    return formGroup.control(name).markAsTouched();
  }
}

class PlatformReactiveForm extends StatelessWidget {
  final Function(Map<String, dynamic> values)? onSubmit;
  final Function(Map<String, dynamic> values)? onReset;
  final List<FormButton>? formButtons;
  final bool showResetButton;
  final String submitLabel;
  final double? height; //高度
  final double? width; //高度
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;
  final double buttonSpacing;
  final List<Widget>? heads;
  final List<Widget>? tails;
  final PlatformReactiveFormController platformReactiveFormController;

  const PlatformReactiveForm({
    super.key,
    required this.platformReactiveFormController,
    this.onSubmit,
    this.onReset,
    this.formButtons,
    this.showResetButton = true,
    this.submitLabel = 'Submit',
    this.height,
    this.width,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing = 0.0,
    this.buttonSpacing = 10.0,
    this.heads,
    this.tails,
  });

  Widget _buildButtonBar() {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    List<Widget> btns = [];
    if (showResetButton) {
      btns.add(TextButton(
        style: style,
        child: CommonAutoSizeText(AppLocalizations.t('Reset')),
        onPressed: () {
          if (onReset != null) {
            var values = platformReactiveFormController.values;
            onReset?.call(values);
          } else {
            platformReactiveFormController.values = {};
          }
        },
      ));
    }
    if (formButtons == null && onSubmit != null) {
      btns.add(TextButton(
        style: mainStyle,
        child: CommonAutoSizeText(AppLocalizations.t(submitLabel)),
        onPressed: () {
          if (onSubmit != null) {
            var values = platformReactiveFormController.values;
            onSubmit?.call(values);
          }
        },
      ));
    } else {
      for (FormButton formButton in formButtons!) {
        btns.add(TextButton(
          style: formButton.buttonStyle,
          child: CommonAutoSizeText(AppLocalizations.t(formButton.label)),
          onPressed: () {
            if (formButton.onTap != null) {
              var values = platformReactiveFormController.values;
              formButton.onTap?.call(values);
            }
          },
        ));
      }
    }

    return OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: buttonSpacing,
      overflowSpacing: buttonSpacing,
      children: btns,
    );
  }

  List<Widget> _buildFormFieldWidget() {
    List<Widget> children = [];
    if (heads != null) {
      children.addAll(heads!);
      children.add(SizedBox(
        height: spacing,
      ));
    }

    for (var i = 0; i < platformReactiveFormController.dataFields.length; i++) {
      PlatformDataField platformDataField =
          platformReactiveFormController.dataFields[i];
      var name = platformDataField.name;
      FocusNode? focusNode = platformReactiveFormController.focusNodes[name];
      children.add(PlatformReactiveDataField(
        platformDataField: platformDataField,
        formGroup: platformReactiveFormController.formGroup,
        focusNode: focusNode,
      ));
      children.add(SizedBox(
        height: spacing,
      ));
    }

    if (tails != null) {
      children.add(SizedBox(
        height: spacing,
      ));
      children.addAll(tails!);
    }

    children.add(SizedBox(
      height: buttonSpacing,
    ));
    children.add(_buildButtonBar());
    children.add(SizedBox(
      height: buttonSpacing,
    ));

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final ReactiveForm reactiveForm = ReactiveForm(
      formGroup: platformReactiveFormController.formGroup,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildFormFieldWidget(),
      ),
    );
    final KeyboardActions formWidget = KeyboardActions(
        config: platformReactiveFormController.keyboardActionsConfig,
        child: SingleChildScrollView(child: reactiveForm));

    return SizedBox(height: height, width: width, child: formWidget);
  }
}
