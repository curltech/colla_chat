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
  smartselect, //多选字段
  multiselect, //多选字段
  multidialog, //多选对话框
  listview, //单选对话框
}

///联系人和群的查询对话框界面，然后进行单选或者多选
class LinkmanGroupSearchWidget extends StatefulWidget {
  final Function(List<String>?) onSelected; //获取返回的选择
  final List<String> selected;
  final bool searchable; //是否有搜索字段
  final SelectType selectType; //查询界面的类型，复杂多选，简单多选，listview，可以包括在showDialog中
  final bool includeLinkman;
  final bool includeGroup;

  const LinkmanGroupSearchWidget(
      {Key? key,
      required this.onSelected,
      required this.selected,
      this.searchable = true,
      this.selectType = SelectType.smartselect,
      this.includeLinkman = true,
      this.includeGroup = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanGroupSearchWidgetState();
}

class _LinkmanGroupSearchWidgetState extends State<LinkmanGroupSearchWidget> {
  TextEditingController textController = TextEditingController();

  String title = '';
  String placeholder = '';
  String? key;

  ValueNotifier<List<Option<String>>> options =
      ValueNotifier<List<Option<String>>>([]);

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
    _search();
  }

  Future<List<Option<String>>> _search({String? key}) async {
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
    options.value = _buildOptions(linkmen, groups);

    return options.value;
    //}
    //return [];
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
    setState(() {});

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
  Widget _buildSmartSelectWidget(BuildContext context) {
    var selector = FutureBuilder<List<Option<String>>>(
      future: _search(),
      builder:
          (BuildContext context, AsyncSnapshot<List<Option<String>>> snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Container();
        }
        return SmartSelectUtil.multiple<String>(
          title: title,
          placeholder: '',
          leading: widget.searchable
              ? SizedBox(
                  width: 300,
                  child: _buildSearchTextField(context),
                )
              : null,
          onChange: (selected) {
            widget.selected.clear();
            widget.selected.addAll(selected);
            widget.onSelected(selected);
          },
          items: snapshot.data!,
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
  Widget _buildMultiSelectWidget(BuildContext context) {
    var selector = FutureBuilder<List<Option<String>>>(
        future: _search(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Option<String>>> snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }
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
            items: snapshot.data!,
          );
        });

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [_buildSearchTextField(context), selector]));
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildMultiSelectDialog(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: options,
        builder:
            (BuildContext context, List<Option<String>> value, Widget? child) {
          var size = MediaQuery.of(context).size;
          return Center(
              child: Container(
                  color: Colors.white,
                  width: size.width * 0.9,
                  height: size.height * 0.9,
                  alignment: Alignment.center,
                  child: ChipMultiSelect(
                    title: Column(children: [
                      AppBarWidget.buildTitleBar(
                          title: Text(
                        AppLocalizations.t(title),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      )),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: _buildSearchTextField(context)),
                    ]),
                    onConfirm: (selected) {
                      widget.onSelected(selected);
                    },
                    items: value,
                  )));
        });
    return selector;
  }

  _onSelected(String? value) {
    widget.onSelected([value!]);
  }

  /// DataListView的单选对话框，使用时外部用对话框包裹
  Widget _buildDataListView(BuildContext context) {
    var dataListView = FutureBuilder<List<Option<String>>>(
        future: _search(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Option<String>>> snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }
          return DataListSingleSelect(
            title: Column(children: [
              AppBarWidget.buildTitleBar(
                  title: Text(
                AppLocalizations.t(title),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              )),
              const SizedBox(
                height: 10,
              ),
              Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: _buildSearchTextField(context)),
            ]),
            items: snapshot.data!,
            onChanged: _onSelected,
          );
        });
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(children: [
          widget.searchable ? _buildSearchTextField(context) : Container(),
          Expanded(child: dataListView)
        ]));
  }

  @override
  Widget build(BuildContext context) {
    Widget selector;
    switch (widget.selectType) {
      case SelectType.smartselect:
        selector = _buildSmartSelectWidget(context);
        break;
      case SelectType.multiselect:
        selector = _buildMultiSelectWidget(context);
        break;
      case SelectType.multidialog:
        selector = _buildMultiSelectDialog(context);
        break;
      case SelectType.listview:
        selector = _buildDataListView(context);
        break;
      default:
        selector = _buildSmartSelectWidget(context);
    }
    return selector;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
