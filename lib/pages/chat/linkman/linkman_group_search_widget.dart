import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

enum SelectType {
  multiSmartSelectField, //多选字段
  dataListMultiSelect, //多选对话框
  chipMultiSelect, //多选对话框
  singleSelect, //单选对话框
  multiSelectDialogField, //多选字段
}

///联系人和群的查询对话框界面，然后进行单选或者多选
///包装在对话框中，await DialogUtil.show
class LinkmanGroupSearchWidget extends StatefulWidget {
  final Function(List<String>?) onSelected; //获取返回的选择
  final List<String> selected;

  final SelectType selectType;
  final bool includeLinkman;
  final bool includeGroup;

  const LinkmanGroupSearchWidget(
      {Key? key,
      required this.onSelected,
      required this.selected,
      this.selectType = SelectType.multiSmartSelectField,
      this.includeLinkman = true,
      this.includeGroup = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanGroupSearchWidgetState();
}

class _LinkmanGroupSearchWidgetState extends State<LinkmanGroupSearchWidget> {
  final TextEditingController textController = TextEditingController();
  final OptionController optionController = OptionController();

  final ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>(<Option<String>>[]);

  String title = '';
  String placeholder = '';
  String? key;

  @override
  initState() {
    super.initState();
    if (widget.includeLinkman && widget.includeGroup) {
      title = 'Linkman and group';
      placeholder = 'linkmen and groups';
    } else if (widget.includeLinkman) {
      title = 'Linkman';
      placeholder = 'linkmen ';
    } else if (widget.includeGroup) {
      title = 'Group';
      placeholder = 'groups';
    }
    optionController.addListener(_update);
    _search();
  }

  _update() {
    options.value = optionController.options;
  }

  Future<void> _search({String? key}) async {
    List<Linkman> linkmen = <Linkman>[];
    List<Group> groups = <Group>[];
    key ??= textController.text;
    //if (this.key != key) {
    this.key = key;
    if (widget.includeLinkman) {
      linkmen = await linkmanService.search(key);
    }
    if (widget.includeGroup) {
      groups = await groupService.search(key);
    }
    optionController.options = _buildOptions(linkmen, groups);
    //}
  }

  List<Option<String>> _buildOptions(
      List<Linkman> linkmen, List<Group> groups) {
    List<Option<String>> options = [];
    if (widget.includeLinkman) {
      for (Linkman linkman in linkmen) {
        bool checked = widget.selected.contains(linkman.peerId);
        Option<String> item = Option<String>(linkman.name, linkman.peerId,
            checked: checked, leading: linkman.avatarImage);
        options.add(item);
      }
    }
    if (widget.includeGroup) {
      for (Group group in groups) {
        bool checked = widget.selected.contains(group.peerId);
        Option<String> item = Option<String>(group.name, group.peerId,
            checked: checked, leading: group.avatarImage);
        options.add(item);
      }
    }

    return options;
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
            _search();
          },
          icon: Icon(
            Icons.search,
            color: myself.primary,
          ),
        ),
      ),
      onChanged: (String? value) async {
        _search();
      },
      onEditingComplete: () async {
        _search();
      },
      onFieldSubmitted: (String? value) async {
        _search();
      },
    );

    return searchTextField;
  }

  /// 复杂多选对话框样式，选择项通过传入的回调方法返回
  Widget _buildMultiSmartSelectField(BuildContext context) {
    var selector = ValueListenableBuilder(
      valueListenable: options,
      builder:
          (BuildContext context, List<Option<String>> value, Widget? child) {
        return SmartSelectUtil.multiple<String>(
          title: title,
          placeholder: '',
          leading: const Icon(Icons.person_add),
          onChange: (selected) {
            widget.selected.clear();
            widget.selected.addAll(selected);
            widget.onSelected(selected);
          },
          items: value,
          modalFilter: false,
          modalFilterAuto: false,
          chipOnDelete: (i) {
            setState(() {
              widget.selected.removeAt(i);
              widget.onSelected(widget.selected);
            });
          },
        );
      },
    );

    return selector;
  }

  /// 简单多选字段，选择项通过传入的回调方法返回
  Widget _buildMultiSelectDialogField(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: options,
        builder:
            (BuildContext context, List<Option<String>> value, Widget? child) {
          return MultiSelectUtil.buildMultiSelectDialogField<String>(
            title: Column(children: [
              AppBarWidget.buildTitleBar(
                  title: Text(
                AppLocalizations.t(title),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              )),
              const SizedBox(
                height: 10,
              ),
              _buildSearchTextField(context),
            ]),
            buttonText: title,
            onConfirm: (selected) {
              widget.onSelected(selected);
            },
            items: value,
          );
        });

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [_buildSearchTextField(context), selector]));
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildChipMultiSelect(BuildContext context) {
    var selector = ChipMultiSelect(
      onConfirm: (selected) {
        widget.onSelected(selected);
      },
      optionController: optionController,
    );
    return selector;
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildDialogWidget(BuildContext context, Widget child) {
    var size = MediaQuery.of(context).size;
    var selector = Center(
        child: Container(
      color: Colors.white,
      width: size.width * 0.9,
      height: size.height * 0.9,
      alignment: Alignment.center,
      child: Column(children: [
        AppBarWidget.buildTitleBar(
            title: Text(
          AppLocalizations.t(title),
          style: const TextStyle(fontSize: 16, color: Colors.white),
        )),
        const SizedBox(
          height: 10,
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: _buildSearchTextField(context)),
        const SizedBox(
          height: 10,
        ),
        Expanded(child: child),
      ]),
    ));
    return selector;
  }

  Widget _buildDataListMultiSelect(BuildContext context) {
    return DataListMultiSelect(
      onConfirm: (selected) {
        widget.onSelected(selected);
      },
      optionController: optionController,
    );
  }

  /// DataListView的单选对话框，使用时外部用对话框包裹
  Widget _buildDataListSingleSelect(BuildContext context) {
    var dataListView = DataListSingleSelect(
      optionController: optionController,
      onChanged: (String? value) {
        widget.onSelected([value!]);
      },
    );
    return dataListView;
  }

  @override
  Widget build(BuildContext context) {
    Widget selector;
    switch (widget.selectType) {
      case SelectType.multiSmartSelectField:
        selector = _buildMultiSmartSelectField(context);
        break;
      case SelectType.multiSelectDialogField:
        selector = _buildMultiSelectDialogField(context);
        break;
      case SelectType.dataListMultiSelect:
        selector =
            _buildDialogWidget(context, _buildDataListMultiSelect(context));
        break;
      case SelectType.chipMultiSelect:
        selector = _buildDialogWidget(context, _buildChipMultiSelect(context));
        break;
      case SelectType.singleSelect:
        selector =
            _buildDialogWidget(context, _buildDataListSingleSelect(context));
        break;
      default:
        selector =
            _buildDialogWidget(context, _buildDataListMultiSelect(context));
    }
    return selector;
  }

  @override
  void dispose() {
    textController.dispose();
    optionController.removeListener(_update);
    super.dispose();
  }
}
