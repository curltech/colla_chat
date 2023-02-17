import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:multi_select_flutter/bottom_sheet/multi_select_bottom_sheet.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/mult_select_dialog.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';

class OptionController with ChangeNotifier {
  List<Option<String>> _options = [];

  List<Option<String>> get options {
    return _options;
  }

  set options(List<Option<String>> options) {
    if (_options != options) {
      _options = options;
      notifyListeners();
    }
  }
}

///利用Option产生的下拉按钮
///利用回调函数onChanged回传选择的按钮
class DataDropdownButton extends StatefulWidget {
  final OptionController optionController;
  final Function(String? value) onChanged;

  const DataDropdownButton(
      {Key? key, required this.optionController, required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataDropdownButtonState();
}

class _DataDropdownButtonState extends State<DataDropdownButton> {
  String? value;

  @override
  void initState() {
    super.initState();
  }

  List<DropdownMenuItem<String>> _buildMenuItems(BuildContext context) {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var item in widget.optionController.options) {
      var label = AppLocalizations.t(item.label);
      var menuItem =
          DropdownMenuItem<String>(value: item.value, child: Text(label));
      if (item.checked) {
        value = item.value;
      }
      menuItems.add(menuItem);
    }
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    var menuItems = _buildMenuItems(context);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(children: [
          DropdownButton<String>(
            dropdownColor: Colors.grey.withOpacity(0.7),
            underline: Container(),
            elevation: 0,
            value: value,
            items: menuItems,
            onChanged: (String? value) {
              setState(() {
                this.value = value;
              });
              widget.onChanged(value);
            },
          ),
        ]));
  }
}

///利用DataListView实现的单选对组件类，可以包装到对话框中
///利用回调函数onChanged回传选择的值
class DataListSingleSelect extends StatefulWidget {
  final OptionController optionController;

  final Function(String? value) onChanged;

  const DataListSingleSelect(
      {Key? key, required this.optionController, required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataListSingleSelectState();
}

class _DataListSingleSelectState extends State<DataListSingleSelect> {
  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildDataListView(BuildContext context) {
    List<TileData> tileData = [];
    for (var item in widget.optionController.options) {
      var label = AppLocalizations.t(item.label);
      var tile =
          TileData(title: label, subtitle: item.value, prefix: item.leading);
      tileData.add(tile);
    }
    return DataListView(tileData: tileData, onTap: _onTap);
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    widget.onChanged(subtitle);
  }

  @override
  Widget build(BuildContext context) {
    var dataListView = _buildDataListView(context);
    List<Widget> children = <Widget>[];
    children.add(Expanded(child: dataListView));
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(children: children));
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}

///利用DataListView实现的多选对组件类，可以包装到对话框中
///利用回调函数onConfirm回传选择的值
class DataListMultiSelect extends StatefulWidget {
  final OptionController optionController;
  final Function(List<String>? value) onConfirm;

  const DataListMultiSelect({
    Key? key,
    required this.optionController,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataListMultiSelectState();
}

class _DataListMultiSelectState extends State<DataListMultiSelect> {
  final ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    _update();
  }

  _update() {
    options.value = widget.optionController.options;
  }

  Widget _buildDataListView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: options,
        builder: (BuildContext context, List<Option<String>> options,
            Widget? child) {
          return ListView.builder(
              //该属性将决定列表的长度是否仅包裹其内容的长度。
              //当ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
              shrinkWrap: true,
              itemCount: this.options.value.length,
              //physics: const NeverScrollableScrollPhysics(),
              controller: ScrollController(),
              itemBuilder: (BuildContext context, int index) {
                Option option = this.options.value[index];

                Widget tileWidget = CheckboxListTile(
                  title: Text(option.label),
                  secondary: option.leading!,
                  value: option.checked,
                  onChanged: (bool? value) {
                    setState(() {
                      option.checked = value!;
                    });
                  },
                );

                return tileWidget;
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    var dataListView = _buildDataListView(context);
    List<Widget> children = <Widget>[];
    children.add(Expanded(child: dataListView));
    children.add(ButtonBar(
      children: [
        TextButton(
            onPressed: () {
              widget.onConfirm(null);
            },
            child: Text(AppLocalizations.t('Cancel'))),
        TextButton(
            onPressed: () {
              List<String> selected = <String>[];
              for (var option in options.value) {
                if (option.checked) {
                  selected.add(option.value);
                }
              }
              widget.onConfirm(selected);
            },
            child: Text(AppLocalizations.t('Ok'))),
      ],
    ));
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(children: children));
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}

///利用Chip实现的多选对组件类，可以包装到对话框中
///利用回调函数onConfirm回传选择的值
class ChipMultiSelect extends StatefulWidget {
  final OptionController optionController;
  final Function(List<String>? value) onConfirm;

  const ChipMultiSelect({
    Key? key,
    required this.optionController,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChipMultiSelectState();
}

class _ChipMultiSelectState extends State<ChipMultiSelect> {
  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    _update();
  }

  _update() {
    options.value = widget.optionController.options;
  }

  Widget _buildChipView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: options,
        builder:
            (BuildContext context, List<Option<String>> value, Widget? child) {
          List<FilterChip> chips = [];
          for (var option in widget.optionController.options) {
            var chip = FilterChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  option.label,
                  style: TextStyle(
                      color: option.checked ? Colors.white : Colors.black),
                ),
                const SizedBox(
                  width: 10,
                ),
                option.leading!,
              ]),
              //avatar: option.leading,
              disabledColor: Colors.white,
              selectedColor: myself.primary,
              backgroundColor: Colors.white,
              showCheckmark: false,
              checkmarkColor: myself.primary,
              selected: option.checked,
              onSelected: (bool value) {
                setState(() {
                  option.checked = value;
                });
              },
            );
            chips.add(chip);
          }
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var chipView = _buildChipView(context);
    List<Widget> children = <Widget>[];
    children.add(Expanded(child: SingleChildScrollView(child: chipView)));
    children.add(ButtonBar(
      children: [
        TextButton(
            onPressed: () {
              widget.onConfirm(null);
            },
            child: Text(AppLocalizations.t('Cancel'))),
        TextButton(
            onPressed: () {
              List<String> selected = <String>[];
              for (var option in widget.optionController.options) {
                if (option.checked) {
                  selected.add(option.value);
                }
              }
              widget.onConfirm(selected);
            },
            child: Text(AppLocalizations.t('Ok'))),
      ],
    ));
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(children: children));
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}

/// 多选对话框字段，这个实现相对比较复杂，样式美观，但是只能用于字段而且错误较多
class SmartSelectUtil {
  ///smart single select button
  static Widget single<T>(
      {required List<Option<T>> items,
      required String title,
      required String placeholder,
      required T selectedValue, //没有checked的时候设置
      required Function(T?) onChange,
      S2ModalType modalType = S2ModalType.popupDialog,
      bool isTwoLine = true,
      bool selected = false,
      bool dense = false,
      bool hideValue = false,
      Widget? leading,
      bool modalFilter = false,
      bool modalFilterAuto = false,
      Widget Function(BuildContext, S2SingleState<T>)? modalHeaderBuilder,
      Widget Function(BuildContext, S2SingleState<T>)? modalFooterBuilder,
      Widget Function(BuildContext, S2SingleState<T>)? modalFilterBuilder,
      Widget Function(BuildContext, S2SingleState<T>)? modalFilterToggleBuilder,
      Function(int)? chipOnDelete}) {
    List<S2Choice<T>> options = [];
    T? value;
    for (Option<T> item in items) {
      S2Choice<T> option =
          S2Choice<T>(value: item.value, title: AppLocalizations.t(item.label));
      options.add(option);
      if (item.checked) {
        value = item.value;
      }
    }
    value ??= selectedValue;

    Widget Function(BuildContext context, S2SingleState<T> state)? tileBuilder;
    if (chipOnDelete != null) {
      tileBuilder = (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: isTwoLine,
          selected: selected,
          dense: dense,
          hideValue: hideValue,
          leading: leading,
          body: S2TileChips(
            chipLength: state.selected.length,
            chipLabelBuilder: (context, i) {
              return Text(state.selected.title![i]);
            },
            chipOnDelete: (i) {
              chipOnDelete(i);
            },
            chipColor: myself.primary,
          ),
        );
      };
    }

    return SmartSelect<T>.single(
      title: AppLocalizations.t(title ?? ''),
      placeholder: AppLocalizations.t(placeholder),
      selectedValue: value!,
      onChange: (selected) {
        onChange(selected.value);
      },
      choiceItems: options,
      modalConfig: S2ModalConfig(
        title: AppLocalizations.t(title ?? ''),
        type: modalType,
        useFilter: modalFilter,
        filterAuto: modalFilterAuto,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(AppOpacity.mdOpacity),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: myself.primary,
          textStyle: const TextStyle(color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: AppOpacity.mdOpacity,
        elevation: 0,
        titleStyle: const TextStyle(color: Colors.white),
        color: myself.primary,
      ),
      modalHeaderBuilder: modalHeaderBuilder,
      modalFooterBuilder: modalFooterBuilder,
      modalFilterBuilder: modalFilterBuilder,
      modalFilterToggleBuilder: modalFilterToggleBuilder,
      tileBuilder: tileBuilder,
    );
  }

  ///smart multiple select button
  static Widget multiple<T>(
      {required List<Option<T>> items,
      required String title,
      required String placeholder,
      required Function(List<T>) onChange,
      S2ModalType modalType = S2ModalType.popupDialog,
      bool isTwoLine = true,
      bool selected = false,
      bool dense = false,
      bool hideValue = false,
      Widget? leading,
      bool modalFilter = false,
      bool modalFilterAuto = false,
      Widget Function(BuildContext, S2MultiState<T>)? modalHeaderBuilder,
      Widget Function(BuildContext, S2MultiState<T>)? modalFooterBuilder,
      Widget Function(BuildContext, S2MultiState<T>)? modalFilterBuilder,
      Widget Function(BuildContext, S2MultiState<T>)? modalFilterToggleBuilder,
      Future<bool> Function(S2MultiState<T>)? onModalWillOpen,
      Widget Function(BuildContext, S2MultiState<T>, S2Choice<T>)?
          choiceBuilder,
      Future<List<S2Choice<T>>> Function(S2ChoiceLoaderInfo<T>)? choiceLoader,
      Function(int)? chipOnDelete}) {
    List<T> selectedValue = [];
    List<S2Choice<T>> options = [];
    for (Option<T> item in items) {
      S2Choice<T> option =
          S2Choice<T>(value: item.value, title: AppLocalizations.t(item.label));
      options.add(option);
      if (item.checked) {
        selectedValue.add(item.value);
      }
    }
    var primary = myself.primary;
    Widget Function(BuildContext context, S2MultiState<T> state)? tileBuilder;
    if (chipOnDelete != null) {
      tileBuilder = (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: isTwoLine,
          selected: selected,
          dense: dense,
          hideValue: hideValue,
          leading: leading,
          body: S2TileChips(
            chipLength: state.selected.length,
            chipLabelBuilder: (context, i) {
              return Text(state.selected.title![i]);
            },
            chipOnDelete: (i) {
              chipOnDelete(i);
            },
            chipColor: myself.primary,
          ),
        );
      };
    }
    return SmartSelect<T>.multiple(
      title: '',
      placeholder: AppLocalizations.t(placeholder),
      selectedValue: selectedValue,
      onChange: (selected) {
        onChange(selected.value);
      },
      choiceItems: options,
      modalConfig: S2ModalConfig(
        title: AppLocalizations.t(title ?? ''),
        type: modalType,
        useFilter: modalFilter,
        filterAuto: modalFilterAuto,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(AppOpacity.mdOpacity),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: myself.primary,
          textStyle: const TextStyle(color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: AppOpacity.mdOpacity,
        elevation: 0,
        titleStyle: const TextStyle(color: Colors.white),
        color: primary,
      ),
      modalHeaderBuilder: modalHeaderBuilder,
      modalFooterBuilder: modalFooterBuilder,
      modalFilterBuilder: modalFilterBuilder,
      modalFilterToggleBuilder: modalFilterToggleBuilder,
      choiceBuilder: choiceBuilder,
      choiceLoader: choiceLoader,
      onModalWillOpen: onModalWillOpen,
      tileBuilder: tileBuilder,
    );
  }
}

/// 多选对话框和多选字段，这个实现相对比较单调
class MultiSelectUtil {
  ///多选对话框字段，用于form的字段选择
  static MultiSelectDialogField<T> buildMultiSelectDialogField<T>({
    required List<Option<T>> items,
    required void Function(List<T>) onConfirm,
    Widget? title,
    String? buttonText,
    Icon? buttonIcon,
    MultiSelectListType? listType,
    BoxDecoration? decoration,
    void Function(List<T>)? onSelectionChanged,
    MultiSelectChipDisplay<T>? chipDisplay,
    bool searchable = false,
    Text? confirmText,
    Text? cancelText,
    Color? barrierColor,
    Color? selectedColor,
    String? searchHint,
    double? dialogHeight,
    double? dialogWidth,
    Color Function(T?)? colorator,
    Color? backgroundColor,
    Color? unselectedColor,
    Icon? searchIcon,
    Icon? closeSearchIcon,
    TextStyle? itemsTextStyle,
    TextStyle? searchTextStyle,
    TextStyle? searchHintStyle,
    TextStyle? selectedItemsTextStyle,
    bool separateSelectedItems = false,
    Color? checkColor,
    void Function(List<T>?)? onSaved,
    String? Function(List<T>?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    GlobalKey<FormFieldState<dynamic>>? key,
  }) {
    List<T> selectedValue = [];
    List<MultiSelectItem<T>> options = [];
    for (Option<T> item in items) {
      MultiSelectItem<T> option =
          MultiSelectItem<T>(item.value, AppLocalizations.t(item.label));
      options.add(option);
      if (item.checked) {
        selectedValue.add(item.value);
      }
    }
    Color primary = myself.primary;
    return MultiSelectDialogField<T>(
      items: options,
      onConfirm: onConfirm,
      initialValue: selectedValue,
      title: title,
      buttonText: Text(AppLocalizations.t(buttonText ?? ''),
          style: TextStyle(color: primary)),
      buttonIcon: buttonIcon,
      listType: listType,
      decoration: decoration,
      onSelectionChanged: onSelectionChanged,
      chipDisplay: chipDisplay,
      searchable: searchable,
      confirmText:
          Text(AppLocalizations.t('Confirm'), style: TextStyle(color: primary)),
      cancelText:
          Text(AppLocalizations.t('Cancel'), style: TextStyle(color: primary)),
      barrierColor: barrierColor,
      selectedColor: primary,
      searchHint: searchHint,
      dialogHeight: dialogHeight,
      dialogWidth: dialogWidth,
      colorator: colorator,
      backgroundColor: Colors.grey.withOpacity(AppOpacity.smOpacity),
      unselectedColor: unselectedColor,
      searchIcon: searchIcon,
      closeSearchIcon: closeSearchIcon,
      itemsTextStyle: itemsTextStyle,
      searchTextStyle: searchTextStyle,
      searchHintStyle: searchHintStyle,
      selectedItemsTextStyle: selectedItemsTextStyle,
      separateSelectedItems: separateSelectedItems,
      checkColor: checkColor,
      onSaved: onSaved,
      validator: validator,
      autovalidateMode: autovalidateMode,
      key: key,
    );
  }

  ///多选对话框，用于直接弹出多选对话框
  static Widget buildMultiSelectDialog<T>({
    required List<Option<T>> items,
    Widget? title,
    void Function(List<T>)? onSelectionChanged,
    void Function(List<T>)? onConfirm,
    MultiSelectListType? listType,
    bool searchable = false,
    Text? confirmText,
    Text? cancelText,
    Color? selectedColor,
    String? searchHint,
    double? height,
    double? width,
    Color? Function(T)? colorator,
    Color? backgroundColor,
    Color? unselectedColor,
    Icon? searchIcon,
    Icon? closeSearchIcon,
    TextStyle? itemsTextStyle,
    TextStyle? searchHintStyle,
    TextStyle? searchTextStyle,
    TextStyle? selectedItemsTextStyle,
    bool separateSelectedItems = false,
    Color? checkColor,
  }) {
    List<T> selectedValue = [];
    List<MultiSelectItem<T>> options = [];
    for (Option<T> item in items) {
      MultiSelectItem<T> option =
          MultiSelectItem<T>(item.value, AppLocalizations.t(item.label));
      options.add(option);
      if (item.checked) {
        selectedValue.add(item.value);
      }
    }
    Color primary = myself.primary;
    Widget dialog = MultiSelectDialog<T>(
      items: options,
      onConfirm: onConfirm,
      initialValue: selectedValue,
      title: title,
      listType: listType,
      onSelectionChanged: onSelectionChanged,
      searchable: searchable,
      confirmText:
          Text(AppLocalizations.t('Confirm'), style: TextStyle(color: primary)),
      cancelText:
          Text(AppLocalizations.t('Cancel'), style: TextStyle(color: primary)),
      selectedColor: primary,
      searchHint: searchHint,
      height: height,
      width: width,
      colorator: colorator,
      backgroundColor: Colors.white,
      unselectedColor: unselectedColor,
      searchIcon: searchIcon,
      closeSearchIcon: closeSearchIcon,
      itemsTextStyle: itemsTextStyle,
      searchTextStyle: searchTextStyle,
      searchHintStyle: searchHintStyle,
      selectedItemsTextStyle: selectedItemsTextStyle,
      separateSelectedItems: separateSelectedItems,
      checkColor: checkColor,
    );

    return dialog;
  }

  ///多选底部对话框，用于直接弹出底部的多选对话框
  static MultiSelectBottomSheet<T> buildMultiSelectBottomSheet<T>({
    required List<Option<T>> items,
    Widget? title,
    void Function(List<T>)? onSelectionChanged,
    void Function(List<T>)? onConfirm,
    MultiSelectListType? listType,
    Text? cancelText,
    Text? confirmText,
    bool searchable = false,
    Color? selectedColor,
    double? initialChildSize,
    double? minChildSize,
    double? maxChildSize,
    Color? Function(T)? colorator,
    Color? unselectedColor,
    Icon? searchIcon,
    Icon? closeSearchIcon,
    TextStyle? itemsTextStyle,
    TextStyle? searchTextStyle,
    String? searchHint,
    TextStyle? searchHintStyle,
    TextStyle? selectedItemsTextStyle,
    bool separateSelectedItems = false,
    Color? checkColor,
  }) {
    List<T> selectedValue = [];
    List<MultiSelectItem<T>> options = [];
    for (Option<T> item in items) {
      MultiSelectItem<T> option =
          MultiSelectItem<T>(item.value, AppLocalizations.t(item.label));
      options.add(option);
      if (item.checked) {
        selectedValue.add(item.value);
      }
    }
    return MultiSelectBottomSheet<T>(
      items: options,
      onConfirm: onConfirm,
      initialValue: selectedValue,
      title: title,
      listType: listType,
      onSelectionChanged: onSelectionChanged,
      searchable: searchable,
      confirmText: confirmText,
      cancelText: cancelText,
      selectedColor: selectedColor,
      searchHint: searchHint,
      colorator: colorator,
      unselectedColor: unselectedColor,
      searchIcon: searchIcon,
      closeSearchIcon: closeSearchIcon,
      itemsTextStyle: itemsTextStyle,
      searchTextStyle: searchTextStyle,
      searchHintStyle: searchHintStyle,
      selectedItemsTextStyle: selectedItemsTextStyle,
      separateSelectedItems: separateSelectedItems,
      checkColor: checkColor,
    );
  }
}
