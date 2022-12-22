import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:multi_select_flutter/bottom_sheet/multi_select_bottom_sheet.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/mult_select_dialog.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';

///利用Option产生的DropdownButton
class DataDropdownButton<T> extends StatefulWidget {
  final String title;
  final List<Option<T>> items;
  final Function(T? value) onChanged;

  const DataDropdownButton(
      {Key? key,
      required this.title,
      required this.items,
      required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataDropdownButtonState<T>();
}

class _DataDropdownButtonState<T> extends State<DataDropdownButton> {
  T? value;

  @override
  void initState() {
    super.initState();
  }

  List<DropdownMenuItem<T>> _buildMenuItems(BuildContext context) {
    List<DropdownMenuItem<T>> menuItems = [];
    for (var item in widget.items) {
      var label = AppLocalizations.t(item.label);
      var menuItem = DropdownMenuItem<T>(value: item.value, child: Text(label));
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
          Text(AppLocalizations.t(widget.title)),
          const Spacer(),
          DropdownButton<T>(
            dropdownColor: Colors.grey.withOpacity(0.7),
            underline: Container(),
            elevation: 0,
            value: value,
            items: menuItems,
            onChanged: (T? value) {
              setState(() {
                this.value = value;
              });
              widget.onChanged(value);
            },
          ),
        ]));
  }
}

class DataListViewSelect<T> extends StatefulWidget {
  final String title;
  final List<Option<T>> items;
  final Function(T? value) onChanged;

  const DataListViewSelect(
      {Key? key,
      required this.title,
      required this.items,
      required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataListViewSelectState<T>();
}

class _DataListViewSelectState<T> extends State<DataDropdownButton> {
  T? value;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildDataListView(BuildContext context) {
    List<TileData> tileData = [];
    for (var item in widget.items) {
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
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: dataListView);
  }
}

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
            chipColor: appDataProvider.themeData.colorScheme.primary,
          ),
        );
      };
    }

    return SmartSelect<T>.single(
      title: AppLocalizations.t(title),
      placeholder: AppLocalizations.t(placeholder),
      selectedValue: value!,
      onChange: (selected) {
        onChange(selected.value);
      },
      choiceItems: options,
      modalConfig: S2ModalConfig(
        type: modalType,
        useFilter: modalFilter,
        filterAuto: modalFilterAuto,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: const S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          // backgroundColor: appDataProvider.themeData.colorScheme.primary,
          // textStyle: const TextStyle(color: Colors.white),
          // iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
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
    var primary = appDataProvider.themeData.colorScheme.primary;
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
            chipColor: appDataProvider.themeData.colorScheme.primary,
          ),
        );
      };
    }
    return SmartSelect<T>.multiple(
      title: AppLocalizations.t(title ?? ''),
      placeholder: AppLocalizations.t(placeholder),
      selectedValue: selectedValue,
      onChange: (selected) {
        onChange(selected.value);
      },
      choiceItems: options,
      modalConfig: S2ModalConfig(
        type: modalType,
        useFilter: modalFilter,
        filterAuto: modalFilterAuto,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.8),
        ),
        headerStyle: const S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          //backgroundColor: appDataProvider.themeData.colorScheme.primary,
          // textStyle: const TextStyle(color: Colors.white),
          // iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
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

class MultiSelectUtil {
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
    Color primary = appDataProvider.themeData.colorScheme.primary;
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
      backgroundColor: Colors.grey.withOpacity(0.8),
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
    Color primary = appDataProvider.themeData.colorScheme.primary;
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
