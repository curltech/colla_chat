import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OptionController with ChangeNotifier {
  late List<Option<String>> _options;

  OptionController({List<Option<String>> options = const <Option<String>>[]}) {
    _options = options;
  }

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
      notifyListeners();
    }
  }

  setSingleChecked(Option<String> option, bool checked) {
    for (var opt in _options) {
      if (opt != option) {
        opt.checked = false;
      }
    }
    setChecked(option, checked);
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
  final OptionController optionController;
  final String? title;
  final Future<List<Option<String>>> Function(String keyword)? onSearch;
  final Function(String? selected) onChanged;

  const DataListSingleSelect(
      {Key? key,
      required this.optionController,
      this.title,
      this.onSearch,
      required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataListSingleSelectState();
}

class _DataListSingleSelectState extends State<DataListSingleSelect> {
  final TextEditingController textController = TextEditingController();
  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    _search();
  }

  _update() {
    options.value = [...widget.optionController.options];
  }

  _search() async {
    if (widget.onSearch != null) {
      List<Option<String>> options =
          await widget.onSearch!(textController.text);
      widget.optionController.options = options;
    } else {
      _update();
    }
  }

  Widget _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
      autofocus: true,
      controller: textController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        fillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
        filled: true,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        suffixIcon: IconButton(
          onPressed: () async {
            await _search();
          },
          icon: Icon(
            Icons.search,
            color: myself.primary,
          ),
        ),
      ),
      onChanged: (String? value) async {
        await _search();
      },
      onEditingComplete: () async {
        await _search();
      },
      onFieldSubmitted: (String? value) async {
        await _search();
      },
    );

    return searchTextField;
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildDialogWidget(BuildContext context, Widget child) {
    Widget selector = child;
    List<Widget> children = [];
    if (StringUtil.isNotEmpty(widget.title)) {
      children.add(
        AppBarWidget.buildTitleBar(
            title: Text(
          AppLocalizations.t(widget.title ?? ''),
          style: const TextStyle(fontSize: 16, color: Colors.white),
        )),
      );
      children.add(
        const SizedBox(
          height: 10,
        ),
      );
    }
    if (widget.onSearch != null) {
      children.add(
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: _buildSearchTextField(context)),
      );
      children.add(
        const SizedBox(
          height: 10,
        ),
      );
    }
    children.add(
      Expanded(child: selector),
    );
    var size = MediaQuery.of(context).size;
    selector = Center(
        child: Container(
      color: Colors.white,
      width: size.width * 0.9,
      height: size.height * 0.9,
      alignment: Alignment.center,
      child: Column(children: children),
    ));
    return selector;
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

                Widget tileWidget = RadioListTile<bool>(
                  groupValue: true,
                  title: Text(option.label),
                  secondary: option.leading,
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: myself.primary,
                  selected: option.checked,
                  value: option.checked,
                  onChanged: (bool? value) {
                    //通知本地变量的改变，刷新界面RadioListTile
                    widget.optionController.setSingleChecked(option, !value!);
                    widget.onChanged(option.value);
                  },
                );

                return tileWidget;
              });
        });
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
  final OptionController optionController;
  final Future<List<Option<String>>> Function(String keyword)? onSearch;
  final String title;
  final Widget? prefix;
  final Widget? suffix;
  final SelectType selectType;
  final Function(String?) onChanged;

  const CustomSingleSelectField({
    Key? key,
    required this.optionController,
    required this.title,
    this.prefix,
    this.suffix,
    this.selectType = SelectType.chipMultiSelect,
    this.onSearch,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomSingleSelectFieldState();
}

class _CustomSingleSelectFieldState extends State<CustomSingleSelectField> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
  }

  _update() {
    for (var option in widget.optionController.options) {
      if (option.checked) {
        textEditingController.text = option.label;
        return;
      }
    }
    textEditingController.text = '';
  }

  Widget _buildSingleSelectField(BuildContext context) {
    var suffix = widget.suffix ??
        const Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
        );
    return TextFormField(
      controller: textEditingController,
      readOnly: true,
      keyboardType: TextInputType.text,
      minLines: 1,
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
                      onSearch: widget.onSearch,
                      onChanged: (String? selected) {
                        Navigator.pop(
                          context,
                          selected,
                        );
                      },
                    );
                  });
              widget.onChanged(selected);
              for (var option in widget.optionController.options) {
                selected = selected ?? '';
                if (option.value == selected) {
                  textEditingController.text = option.label;
                  break;
                }
              }
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
  dataListMultiSelectField, //多选对话框
  chipMultiSelectField, //多选对话框
  singleSelect, //单选对话框
  singleSelectField,
}

///利用Chip实现的多选对组件类，可以包装到对话框中
///利用回调函数onConfirm回传选择的值
class CustomMultiSelect extends StatefulWidget {
  final OptionController optionController;
  final Future<List<Option<String>>> Function(String keyword)? onSearch;
  final Function(List<String>? selected) onConfirm;
  final String? title;
  final SelectType selectType;

  const CustomMultiSelect({
    Key? key,
    required this.optionController,
    required this.onConfirm,
    this.onSearch,
    this.title,
    this.selectType = SelectType.chipMultiSelect,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomMultiSelectState();
}

class _CustomMultiSelectState extends State<CustomMultiSelect> {
  final TextEditingController textController = TextEditingController();

  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
    //初始化数据
    _search();
  }

  _update() {
    options.value = widget.optionController.copy();
  }

  _search() async {
    if (widget.onSearch != null) {
      List<Option<String>> options =
          await widget.onSearch!(textController.text);
      widget.optionController.options = options;
    }
  }

  Widget _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
      autofocus: true,
      controller: textController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        fillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
        filled: true,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        suffixIcon: IconButton(
          onPressed: () async {
            await _search();
          },
          icon: Icon(
            Icons.search,
            color: myself.primary,
          ),
        ),
      ),
      onChanged: (String? value) async {
        await _search();
      },
      onEditingComplete: () async {
        await _search();
      },
      onFieldSubmitted: (String? value) async {
        await _search();
      },
    );

    return searchTextField;
  }

  //对话框界面的数据必须使用本地数据，不能使用控制器数据，否则边选择数据边改了
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
                option.leading ?? Container(),
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

  //对话框界面的数据必须使用本地数据，不能使用控制器数据，否则边选择数据边改了
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
                  secondary: option.leading,
                  controlAffinity: ListTileControlAffinity.trailing,
                  value: option.checked,
                  selected: option.checked,
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
    List<Widget> children = [];
    if (StringUtil.isNotEmpty(widget.title)) {
      children.add(
        AppBarWidget.buildTitleBar(
            title: Text(
          AppLocalizations.t(widget.title ?? ''),
          style: const TextStyle(fontSize: 16, color: Colors.white),
        )),
      );
      children.add(
        const SizedBox(
          height: 10,
        ),
      );
    }
    if (widget.onSearch != null) {
      children.add(
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: _buildSearchTextField(context)),
      );
      children.add(
        const SizedBox(
          height: 10,
        ),
      );
    }
    children.add(
      Expanded(child: selector),
    );
    var size = MediaQuery.of(context).size;
    selector = Center(
        child: Container(
      color: Colors.white,
      width: size.width * 0.9,
      height: size.height * 0.9,
      alignment: Alignment.center,
      child: Column(children: children),
    ));
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
  final Future<List<Option<String>>> Function(String keyword)? onSearch;
  final Function(List<String>? value)? onConfirm;
  final String title;
  final Widget? prefix;
  final Widget? suffix;
  final SelectType selectType;
  final OptionController optionController;

  const CustomMultiSelectField(
      {Key? key,
      required this.optionController,
      required this.onSearch,
      this.onConfirm,
      required this.title,
      this.prefix,
      this.suffix,
      this.selectType = SelectType.chipMultiSelect})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomMultiSelectFieldState();
}

class _CustomMultiSelectFieldState extends State<CustomMultiSelectField> {
  ValueNotifier<bool> optionsChanged = ValueNotifier<bool>(true);
  ValueNotifier<bool> chipVisible = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    widget.optionController.addListener(_update);
  }

  _update() {
    optionsChanged.value = !optionsChanged.value;
  }

  //字段的数据使用控制器数据，直接修改，optionsChanged用于表示控制器数据改变了
  Widget _buildSelectedChips(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: optionsChanged,
        builder: (BuildContext context, bool optionsChanged, Widget? child) {
          List<Chip> chips = [];
          for (var option in widget.optionController.options) {
            if (option.checked) {
              var chip = Chip(
                label: Text(
                  option.label,
                  style: const TextStyle(color: Colors.black),
                ),
                avatar: option.leading,
                backgroundColor: Colors.white,
                deleteIconColor: myself.primary,
                onDeleted: () {
                  widget.optionController.setChecked(option, false);
                  widget.onConfirm!(widget.optionController.selected);
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
        const Icon(
          Icons.chevron_right,
          color: Colors.white,
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
                  onSearch: widget.onSearch,
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
