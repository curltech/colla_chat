import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

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
      Widget? leading,
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
          isTwoLine: true,
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
      modalType: modalType,
      modalConfig: S2ModalConfig(
        type: modalType,
        useFilter: false,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: appDataProvider.themeData.colorScheme.primary,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        //titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
      ),
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
      Widget? leading,
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
    Widget Function(BuildContext context, S2MultiState<T> state)? tileBuilder;
    if (chipOnDelete != null) {
      tileBuilder = (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: true,
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
      title: AppLocalizations.t(title),
      placeholder: AppLocalizations.t(placeholder),
      selectedValue: selectedValue,
      onChange: (selected) {
        onChange(selected.value);
      },
      choiceItems: options,
      modalType: modalType,
      modalConfig: S2ModalConfig(
        type: modalType,
        useFilter: false,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: appDataProvider.themeData.colorScheme.primary,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        //titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
      ),
      tileBuilder: tileBuilder,
    );
  }
}
