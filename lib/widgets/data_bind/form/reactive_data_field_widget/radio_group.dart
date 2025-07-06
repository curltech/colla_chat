import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ReactiveRadioGroup<T> extends ReactiveFormField<T, T> {
  ReactiveRadioGroup({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    ReactiveFormFieldCallback<T>? onChanged,
    double width = 120,
    MouseCursor? mouseCursor,
    bool toggleable = false,
    Color? activeColor,
    WidgetStateProperty<Color?>? fillColor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
    builder: (field) {
      List<Widget> radioChildren = [];
      if (options.isNotEmpty) {
        T? groupValue = field.value;
        for (var i = 0; i < options.length; ++i) {
          var option = options[i];
          var radio = Radio<T>(
            onChanged: (T? value) {
              field.didChange(value);
              onChanged?.call(field.control);
            },
            value: option.value,
            groupValue: groupValue,
            mouseCursor: mouseCursor,
            toggleable: toggleable,
            activeColor: activeColor,
            fillColor: fillColor,
            focusColor: focusColor,
            hoverColor: hoverColor,
            overlayColor: overlayColor,
            splashRadius: splashRadius,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
            focusNode: focusNode,
            autofocus: autofocus,
          );
          var row = SizedBox(
              width: width,
              child: Row(
                children: [
                  radio,
                  Expanded(
                      child: CommonAutoSizeText(
                          AppLocalizations.t(option.label)))
                ],
              ));
          radioChildren.add(row);
        }
      }

      return Wrap(
        children: radioChildren,
      );
    },
  );
}