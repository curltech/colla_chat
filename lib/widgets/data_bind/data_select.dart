import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  setChecked(Option<String> option, bool checked) {
    if (option.checked != checked) {
      option.checked = checked;
      _options = [..._options];
      notifyListeners();
    }
  }

  setSelectedChecked(String selected, bool checked) {
    Option<String>? selectedOption;
    for (var option in _options) {
      option.checked = false;
      if (option.value == selected) {
        selectedOption = option;
      }
    }
    if (selectedOption != null) {
      setChecked(selectedOption, true);
    }
  }

  List<Option<String>> get selectedOptions {
    List<Option<String>> selected = <Option<String>>[];
    for (var option in _options) {
      if (option.checked) {
        selected.add(option);
      }
    }
    return selected;
  }

  List<String> get selected {
    List<String> selected = <String>[];
    for (var option in _options) {
      if (option.checked) {
        selected.add(option.value);
      }
    }
    return selected;
  }

  List<Option<String>> copy() {
    List<Option<String>> options = [];
    for (var option in _options) {
      options.add(option.copy());
    }

    return options;
  }
}

///利用Option产生的下拉按钮
///利用回调函数onChanged回传选择的按钮
class DataDropdownButton extends StatefulWidget {
  final OptionController optionController;
  final Function(String? selected) onChanged;
  final String? title;

  const DataDropdownButton(
      {Key? key,
      required this.optionController,
      this.title,
      required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataDropdownButtonState();
}

class _DataDropdownButtonState extends State<DataDropdownButton> {
  String? selected;

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
        selected = item.value;
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
            value: selected,
            items: menuItems,
            onChanged: (String? value) {
              setState(() {
                selected = value;
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
  late final OptionController optionController;
  final String? title;
  final Function(String? selected) onChanged;

  DataListSingleSelect(
      {Key? key,
      OptionController? optionController,
      this.title,
      required this.onChanged})
      : super(key: key) {
    if (optionController == null) {
      this.optionController = OptionController();
    } else {
      this.optionController = optionController;
    }
  }

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

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildDialogWidget(BuildContext context, Widget child) {
    Widget selector = child;
    if (StringUtil.isNotEmpty(widget.title)) {
      var size = MediaQuery.of(context).size;
      selector = Center(
          child: Container(
        color: Colors.white,
        width: size.width * 0.9,
        height: size.height * 0.9,
        alignment: Alignment.center,
        child: Column(children: [
          AppBarWidget.buildTitleBar(
              title: Text(
            AppLocalizations.t(widget.title ?? ''),
            style: const TextStyle(fontSize: 16, color: Colors.white),
          )),
          const SizedBox(
            height: 10,
          ),
          Expanded(child: selector),
        ]),
      ));
    }
    return selector;
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

    return _buildDialogWidget(context, dataListView);
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}

class CustomSingleSelectField extends StatefulWidget {
  late final OptionController optionController;
  final List<Option<String>>? options;
  final Function(List<String>? value)? onConfirm;
  final String title;
  final Widget? prefix;
  final Widget? suffix;
  final SelectType selectType;
  final Function(String?) onChanged;

  CustomSingleSelectField({
    Key? key,
    OptionController? optionController,
    this.options,
    this.onConfirm,
    required this.title,
    this.prefix,
    this.suffix,
    this.selectType = SelectType.chipMultiSelect,
    required this.onChanged,
  }) : super(key: key) {
    if (optionController == null) {
      this.optionController = OptionController();
      if (options != null) {
        this.optionController.options = options!;
      }
    } else {
      this.optionController = optionController;
    }
  }

  @override
  State<StatefulWidget> createState() => _CustomSingleSelectFieldState();
}

class _CustomSingleSelectFieldState extends State<CustomSingleSelectField> {
  TextEditingController textEditingController = TextEditingController();

  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    _update();
  }

  _update() {
    options.value = [...widget.optionController.options];
  }

  Widget _buildSingleSelectField(BuildContext context) {
    var suffix = widget.suffix ??
        Icon(
          Icons.arrow_drop_down,
          color: myself.secondary,
        );
    return TextFormField(
      controller: textEditingController,
      keyboardType: TextInputType.text,
      minLines: 1,
      initialValue: '',
      decoration: InputDecoration(
        labelText: AppLocalizations.t(widget.title ?? ''),
        fillColor: Colors.grey.withOpacity(AppOpacity.xlOpacity),
        filled: true,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        prefixIcon: widget.prefix,
        suffixIcon: InkWell(
            child: suffix,
            onTap: () async {
              String? selected = await DialogUtil.show(
                  context: context,
                  builder: (BuildContext context) {
                    return DataListSingleSelect(
                      title: widget.title,
                      optionController: widget.optionController,
                      onChanged: (String? selected) {
                        Navigator.pop(
                          context,
                          selected,
                        );
                      },
                    );
                  });
              widget.onChanged(selected);
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleSelectField(context);
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}

enum SelectType {
  dataListMultiSelect, //多选对话框
  chipMultiSelect, //多选对话框
  singleSelect, //单选对话框
}

///利用Chip实现的多选对组件类，可以包装到对话框中
///利用回调函数onConfirm回传选择的值
class CustomMultiSelect extends StatefulWidget {
  late final OptionController optionController;
  final Function(List<String>? selected) onConfirm;
  final String? title;
  final SelectType selectType;

  CustomMultiSelect({
    Key? key,
    OptionController? optionController,
    required this.onConfirm,
    this.title,
    this.selectType = SelectType.chipMultiSelect,
  }) : super(key: key) {
    if (optionController == null) {
      this.optionController = OptionController();
    } else {
      this.optionController = optionController;
    }
  }

  @override
  State<StatefulWidget> createState() => _CustomMultiSelectState();
}

class _CustomMultiSelectState extends State<CustomMultiSelect> {
  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    _update();
  }

  _update() {
    options.value = widget.optionController.copy();
  }

  Widget _buildChipView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: options,
        builder: (BuildContext context, List<Option<String>> options,
            Widget? child) {
          List<FilterChip> chips = [];
          for (var option in options) {
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
                option.checked = value;
                this.options.value = [...options];
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

  Widget _buildDataListView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: options,
        builder: (BuildContext context, List<Option<String>> options,
            Widget? child) {
          return ListView.builder(
              //采用options本地的变量，不影响控制器的数据，只有确认按钮才会影响控制器数据
              shrinkWrap: true,
              itemCount: options.length,
              //physics: const NeverScrollableScrollPhysics(),
              controller: ScrollController(),
              itemBuilder: (BuildContext context, int index) {
                Option<String> option = options[index];

                Widget tileWidget = CheckboxListTile(
                  title: Text(option.label),
                  secondary: option.leading!,
                  value: option.checked,
                  onChanged: (bool? value) {
                    option.checked = value!;
                    //通知本地变量的改变，刷新界面CheckboxListTile
                    this.options.value = [...options];
                  },
                );

                return tileWidget;
              });
        });
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildDialogWidget(BuildContext context, Widget child) {
    Widget selector = child;
    if (StringUtil.isNotEmpty(widget.title)) {
      var size = MediaQuery.of(context).size;
      selector = Center(
          child: Container(
        color: Colors.white,
        width: size.width * 0.9,
        height: size.height * 0.9,
        alignment: Alignment.center,
        child: Column(children: [
          AppBarWidget.buildTitleBar(
              title: Text(
            AppLocalizations.t(widget.title ?? ''),
            style: const TextStyle(fontSize: 16, color: Colors.white),
          )),
          const SizedBox(
            height: 10,
          ),
          Expanded(child: selector),
        ]),
      ));
    }
    return selector;
  }

  @override
  Widget build(BuildContext context) {
    Widget selectView;
    if (widget.selectType == SelectType.chipMultiSelect) {
      selectView = _buildChipView(context);
    } else if (widget.selectType == SelectType.dataListMultiSelect) {
      selectView = _buildDataListView(context);
    } else {
      selectView = _buildChipView(context);
    }
    List<Widget> children = <Widget>[];
    children.add(Expanded(child: SingleChildScrollView(child: selectView)));
    children.add(ButtonBar(
      children: [
        TextButton(
            onPressed: () {
              widget.onConfirm(null);
            },
            child: Text(AppLocalizations.t('Cancel'))),
        TextButton(
            onPressed: () {
              widget.optionController.options = options.value;
              widget.onConfirm(widget.optionController.selected);
            },
            child: Text(AppLocalizations.t('Ok'))),
      ],
    ));
    return _buildDialogWidget(
        context,
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(children: children)));
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}

///利用Chip实现的多选字段组件类，将ChipMultiSelect包装到对话框中
///利用回调函数onConfirm回传选择的值
class CustomMultiSelectField extends StatefulWidget {
  late final OptionController optionController;
  final Function(List<String>? value)? onConfirm;
  final String title;
  final Widget? prefix;
  final Widget? suffix;
  final SelectType selectType;

  CustomMultiSelectField(
      {Key? key,
      OptionController? optionController,
      this.onConfirm,
      required this.title,
      this.prefix,
      this.suffix,
      this.selectType = SelectType.chipMultiSelect})
      : super(key: key) {
    if (optionController == null) {
      this.optionController = OptionController();
    } else {
      this.optionController = optionController;
    }
  }

  @override
  State<StatefulWidget> createState() => _CustomMultiSelectFieldState();
}

class _CustomMultiSelectFieldState extends State<CustomMultiSelectField> {
  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);
  ValueNotifier<bool> chipVisible = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    _update();
  }

  _update() {
    options.value = [...widget.optionController.options];
  }

  Widget _buildSelectedChips(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: options,
        builder: (BuildContext context, List<Option<String>> options,
            Widget? child) {
          List<Chip> chips = [];
          for (var option in widget.optionController.options) {
            if (option.checked) {
              var chip = Chip(
                label: Text(
                  option.label,
                  style: const TextStyle(color: Colors.black),
                ),
                avatar: option.leading!,
                backgroundColor: Colors.white,
                deleteIconColor: myself.primary,
                onDeleted: () {
                  widget.optionController.setChecked(option, false);
                },
              );
              chips.add(chip);
            }
          }
          if (chips.isNotEmpty) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            );
          } else {
            return Container();
          }
        });
  }

  Widget _buildMultiSelectField(BuildContext context) {
    var suffix = widget.suffix ??
        Icon(
          Icons.chevron_right,
          color: myself.secondary,
        );
    return Column(children: [
      ListTile(
        leading: widget.prefix,
        title: Text(AppLocalizations.t(widget.title ?? '')),
        trailing: suffix,
        onTap: () async {
          List<String>? selected = await DialogUtil.show(
              context: context,
              builder: (BuildContext context) {
                return CustomMultiSelect(
                  title: widget.title,
                  selectType: widget.selectType,
                  optionController: widget.optionController,
                  onConfirm: (List<String>? selected) {
                    Navigator.pop(
                      context,
                      selected,
                    );
                  },
                );
              });
          if (widget.onConfirm != null) {
            widget.onConfirm!(selected);
          }
        },
        onLongPress: () {
          chipVisible.value = !chipVisible.value;
        },
      ),
      const SizedBox(
        height: 5.0,
      ),
      ValueListenableBuilder(
          valueListenable: chipVisible,
          builder: (BuildContext context, bool chipVisible, Widget? child) {
            return Visibility(
                visible: chipVisible,
                child: SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                        child: _buildSelectedChips(context))));
          }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildMultiSelectField(context);
  }

  @override
  void dispose() {
    widget.optionController.removeListener(_update);
    super.dispose();
  }
}
