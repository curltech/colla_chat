import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:choice/choice.dart';

enum ItemType { chip, checkbox, radio, switcher }

class ReactiveChoice<T> extends ReactiveFormField<T, Set<T>> {
  ReactiveChoice({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    String? title,
    bool multiple = false,
    ItemType itemType = ItemType.chip,
    bool clearable = false,
    bool confirmation = false,
    bool loading = false,
    bool error = false,
    void Function(FormControl<T>)? onChanged,
    bool Function(ChoiceController<T>, int)? itemSkip,
    String Function(int)? itemGroup,
    Widget Function(ChoiceController<T>)? dividerBuilder,
    Widget Function(ChoiceController<T>)? leadingBuilder,
    Widget Function(ChoiceController<T>)? trailingBuilder,
    Widget Function(ChoiceController<T>)? placeholderBuilder,
    Widget Function(ChoiceController<T>)? errorBuilder,
    Widget Function(ChoiceController<T>)? loaderBuilder,
    int Function(String, String)? groupSort,
    Widget Function(Widget Function(int), int)? groupBuilder,
    Widget Function(Widget, Widget)? groupItemBuilder,
    Widget Function(String, List<int>)? groupHeaderBuilder,
    Widget Function(ChoiceController<T>)? modalHeaderBuilder,
    Widget Function(ChoiceController<T>)? modalFooterBuilder,
    Widget Function(ChoiceController<T>)? modalSeparatorBuilder,
    FlexFit modalFit = FlexFit.loose,
    Widget Function(ChoiceController<T>, void Function())? anchorBuilder,
    Future<List<T>?> Function(BuildContext, Widget)? promptDelegate,
    bool searchable = false,
    void Function(String)? onSearch,
  }) : super(
          builder: (field) {
            Widget Function(ChoiceController<T>, int) itemBuilder;
            Widget Function(Widget Function(int), int)? listBuilder;
            Set<T> value = field.value ?? {};
            List<T> selected = [];
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              value.add(option.value);
              if (option.selected) {
                selected.add(option.value);
              }
            }
            switch (itemType) {
              case ItemType.chip:
                itemBuilder = (state, i) {
                  return ChoiceChip(
                    selected: options[i].selected,
                    onSelected: state.onSelected(options[i].value),
                    label: Text(options[i].label),
                  );
                };
                listBuilder = ChoiceList.createWrapped(
                  spacing: 10,
                  runSpacing: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                );
                break;
              case ItemType.checkbox:
                itemBuilder = (state, i) {
                  return CheckboxListTile(
                    value: options[i].selected,
                    onChanged: state.onSelected(options[i].value),
                    title: Text(options[i].label),
                  );
                };
                listBuilder = ChoiceList.createVirtualized(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                );
                break;
              case ItemType.radio:
                itemBuilder = (state, i) {
                  return RadioListTile<T>(
                    value: options[i].value,
                    groupValue: state.single,
                    onChanged: (value) {
                      options[i].value;
                    },
                    title: Text(options[i].label),
                  );
                };
                listBuilder = ChoiceList.createVirtualized(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                );
                break;
              case ItemType.switcher:
                itemBuilder = (state, i) {
                  return SwitchListTile(
                    value: options[i].selected,
                    onChanged: (value) {
                      options[i].value;
                    },
                    title: Text(options[i].label),
                  );
                };
                listBuilder = ChoiceList.createVirtualized(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                );
                break;
            }

            return PromptedChoice<T>(
              title: title,
              multiple: multiple,
              clearable: clearable,
              confirmation: confirmation,
              loading: loading,
              error: error,
              value: selected,
              onChanged: (changes) {
                Set<T> values = field.value ?? {};
                values.addAll(changes);
                field.didChange(values);
                onChanged?.call(field.control);
              },
              itemCount: options.length,
              itemBuilder: itemBuilder,
              itemSkip: itemSkip,
              itemGroup: itemGroup,
              dividerBuilder: dividerBuilder,
              leadingBuilder: leadingBuilder,
              trailingBuilder: trailingBuilder,
              placeholderBuilder: placeholderBuilder,
              errorBuilder: errorBuilder,
              loaderBuilder: loaderBuilder,
              groupSort: groupSort,
              groupBuilder: groupBuilder,
              groupItemBuilder: groupItemBuilder,
              groupHeaderBuilder: groupHeaderBuilder,
              listBuilder: listBuilder,
              modalHeaderBuilder: modalHeaderBuilder,
              modalFooterBuilder: modalFooterBuilder,
              modalSeparatorBuilder: modalSeparatorBuilder,
              modalFit: modalFit = FlexFit.loose,
              anchorBuilder: anchorBuilder,
              promptDelegate: promptDelegate,
              searchable: searchable = false,
              onSearch: onSearch,
            );
          },
        );
}
