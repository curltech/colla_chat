import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

enum ChipType { chip, filter, action, choice, avatar, input }

class ReactiveChipGroup<T> extends ReactiveFormField<T, Set<T>> {
  ReactiveChipGroup({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    ChipType chipType = ChipType.filter,
    ReactiveFormFieldCallback<T>? onSelected,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? labelPadding,
    Widget? deleteIcon,
    void Function(T value)? onDeleted,
    Color? deleteIconColor,
    String? deleteButtonTooltipMessage,
    double? pressElevation,
    Color? disabledColor,
    Color? selectedColor,
    String? tooltip,
    BorderSide? side,
    OutlinedBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    WidgetStateProperty<Color?>? color,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? materialTapTargetSize,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    IconThemeData? iconTheme,
    Color? selectedShadowColor,
    bool? showCheckmark,
    Color? checkmarkColor,
    ShapeBorder avatarBorder = const CircleBorder(),
    BoxConstraints? avatarBoxConstraints,
    BoxConstraints? deleteIconBoxConstraints,
    ChipAnimationStyle? chipAnimationStyle,
    MouseCursor? mouseCursor,
  }) : super(builder: (field) {
          Set<T>? value = field.value;
          List<Widget> chipChildren = [];
          if (options.isNotEmpty) {
            value ??= {};
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              Widget chip;
              switch (chipType) {
                case ChipType.filter:
                  // like checkbox chip
                  chip = FilterChip(
                    onSelected: (bool selected) {
                      if (!selected) {
                        value!.remove(option.value);
                      } else if (selected) {
                        value!.add(option.value);
                      }
                      field.control.markAsTouched(updateParent: false);
                      field.didChange(value);
                      onSelected?.call(field.control);
                    },
                    avatar: option.leading,
                    label: Text(
                      option.label,
                      style: TextStyle(
                          color: option.selected ? Colors.white : Colors.black),
                    ),
                    labelStyle: labelStyle,
                    labelPadding: labelPadding,
                    selected: option.selected,
                    deleteIcon: deleteIcon,
                    onDeleted: () {
                      value!.remove(option.value);
                      field.didChange(value);
                      onDeleted?.call(option.value);
                    },
                    deleteIconColor: deleteIconColor,
                    deleteButtonTooltipMessage: deleteButtonTooltipMessage,
                    pressElevation: pressElevation,
                    disabledColor: disabledColor,
                    selectedColor: selectedColor,
                    tooltip: tooltip,
                    side: side,
                    shape: shape,
                    clipBehavior: clipBehavior,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    color: color,
                    backgroundColor: backgroundColor,
                    padding: padding,
                    visualDensity: visualDensity,
                    materialTapTargetSize: materialTapTargetSize,
                    elevation: elevation,
                    shadowColor: shadowColor,
                    surfaceTintColor: surfaceTintColor,
                    iconTheme: iconTheme,
                    selectedShadowColor: selectedShadowColor,
                    showCheckmark: showCheckmark,
                    checkmarkColor: checkmarkColor,
                    avatarBorder: avatarBorder,
                    avatarBoxConstraints: avatarBoxConstraints,
                    deleteIconBoxConstraints: deleteIconBoxConstraints,
                    chipAnimationStyle: chipAnimationStyle,
                    mouseCursor: mouseCursor,
                  );
                  break;
                case ChipType.chip:
                  // normal chip, can be deleted
                  chip = Chip(
                    label: Text(
                      option.label,
                      style: TextStyle(
                          color: option.selected ? Colors.white : Colors.black),
                    ),
                    avatar: option.leading,
                    labelStyle: labelStyle,
                    labelPadding: labelPadding,
                    deleteIcon: deleteIcon,
                    onDeleted: () {
                      value!.remove(option.value);
                      field.didChange(value);
                      onDeleted?.call(option.value);
                    },
                    deleteIconColor: deleteIconColor,
                    deleteButtonTooltipMessage: deleteButtonTooltipMessage,
                    side: side,
                    shape: shape,
                    clipBehavior: clipBehavior,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    color: color,
                    backgroundColor: backgroundColor,
                    padding: padding,
                    visualDensity: visualDensity,
                    materialTapTargetSize: materialTapTargetSize,
                    elevation: elevation,
                    shadowColor: shadowColor,
                    surfaceTintColor: surfaceTintColor,
                    iconTheme: iconTheme,
                    avatarBoxConstraints: avatarBoxConstraints,
                    deleteIconBoxConstraints: deleteIconBoxConstraints,
                    chipAnimationStyle: chipAnimationStyle,
                    mouseCursor: mouseCursor,
                  );
                  break;
                case ChipType.action:
                  // like button chip
                  chip = ActionChip(
                    label: Text(
                      option.label,
                      style: TextStyle(
                          color: option.selected ? Colors.white : Colors.black),
                    ),
                    avatar: option.leading,
                    onPressed: () {},
                  );
                  break;
                case ChipType.choice:
                  // like radio chip
                  chip = ChoiceChip(
                    label: Text(
                      option.label,
                      style: TextStyle(
                          color: option.selected ? Colors.white : Colors.black),
                    ),
                    selected: false,
                    avatar: option.leading,
                    onSelected: (v) {},
                  );
                  break;
                case ChipType.input:
                  // put normal chip into TextField, can be deleted
                  chip = InputChip(
                    label: Text(
                      option.label,
                      style: TextStyle(
                          color: option.selected ? Colors.white : Colors.black),
                    ),
                    avatar: option.leading,
                    onSelected: (v) {},
                    onDeleted: () {},
                    onPressed: () {},
                  );
                  break;
                case ChipType.avatar:
                  // image avatar
                  chip = CircleAvatar();
                  break;
              }
              chipChildren.add(chip);
            }
          }
          return Wrap(
            spacing: 5,
            runSpacing: 5,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            runAlignment: WrapAlignment.start,
            children: chipChildren,
          );
        });
}
