import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
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

///利用Option产生的下拉按钮
///利用回调函数onChanged回传选择的按钮
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

///利用DataListView实现的单选对组件类，可以包装到对话框中
///利用回调函数onChanged回传选择的值
class DataListSingleSelect<T> extends StatefulWidget {
  final String title;
  final List<Option<T>> items;
  //用泛型T会报错
  final Function(String? value) onChanged;

  const DataListSingleSelect(
      {Key? key,
      required this.title,
      required this.items,
      required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataListSingleSelectState<T>();
}

class _DataListSingleSelectState<T> extends State<DataListSingleSelect> {
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

///利用DataListView实现的多选对组件类，可以包装到对话框中
///利用回调函数onChanged回传选择的值
class DataListMultiSelect<T> extends StatefulWidget {
  final String title;
  final List<Option<T>> items;
  final Function(List<T?> value) onChanged;

  const DataListMultiSelect({
    Key? key,
    required this.title,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataListMultiSelectState<T>();
}

class _DataListMultiSelectState<T> extends State<DataListMultiSelect> {
  List<T> values = <T>[];

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
    return ListView.builder(
        //该属性将决定列表的长度是否仅包裹其内容的长度。
        // 当 ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
        shrinkWrap: true,
        itemCount: widget.items.length,
        //physics: const NeverScrollableScrollPhysics(),
        controller: ScrollController(),
        itemBuilder: (BuildContext context, int index) {
          Option option = widget.items[index];

          Widget tileWidget = CheckboxListTile(
            title: Text(option.label),
            value: option.value,
            selected: option.checked,
            checkColor: myself.primary,
            onChanged: (bool? value) {
              if (value != null && value) {
                values.add(option.value);
              } else {
                values.remove(option.value);
              }
              widget.onChanged(values);
            },
          );

          return tileWidget;
        });
  }

  @override
  Widget build(BuildContext context) {
    var dataListView = _buildDataListView(context);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: dataListView);
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
