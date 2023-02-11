import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/contact.dart';
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
  final Function(List<String>) onSelected; //获取返回的选择
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
  List<Linkman> linkmen = [];
  List<Group> groups = [];
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
  }

  Future<bool> _search({String? key}) async {
    key ??= textController.text;
    if (this.key != key) {
      this.key = key;
      if (widget.includeLinkman) {
        linkmen = await linkmanService.search(key);
      }
      if (widget.includeGroup) {
        groups = await groupService.search(key);
      }
      logger.i('search complete');
      return true;
    }
    return false;
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
            bool result = await _search();
            if (result) {
              setState(() {});
            }
          },
          icon: Icon(
            Icons.search,
            color: myself.primary,
          ),
        ),
      ),
      onChanged: (String? value) async {
        bool result = await _search();
        if (result) {
          setState(() {});
        }
      },
      onEditingComplete: () async {
        bool result = await _search();
        if (result) {
          setState(() {});
        }
      },
      onFieldSubmitted: (String? value) async {
        bool result = await _search();
        if (result) {
          setState(() {});
        }
      },
    );

    return searchTextField;
  }

  List<Option<String>> _buildOptions() {
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

  /// 复杂多选对话框样式，选择项通过传入的回调方法返回
  Widget _buildSmartSelectWidget(BuildContext context) {
    var selector = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          var options = _buildOptions();
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
            items: options,
            modalFilter: false,
            modalFilterAuto: false,
            chipOnDelete: (i) {
              setState(() {
                widget.selected.removeAt(i);
                widget.onSelected(widget.selected);
              });
            },
          );
        });

    return selector;
  }

  /// 简单多选字段，选择项通过传入的回调方法返回
  Widget _buildMultiSelectWidget(BuildContext context) {
    var selector = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          var options = _buildOptions();
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
              widget.selected.clear();
              widget.selected.addAll(selected);
              widget.onSelected(selected);
            },
            items: options,
          );
        });

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [_buildSearchTextField(context), selector]));
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildMultiSelectDialog(BuildContext context) {
    var selector = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          return MultiSelectUtil.buildMultiSelectDialog<String>(
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
            onConfirm: (selected) {
              widget.selected.clear();
              widget.selected.addAll(selected);
              widget.onSelected(selected);
            },
            items: _buildOptions(),
          );
        });
    return selector;
  }

  _onSelected(String? value) {
    widget.onSelected([value!]);
  }

  /// DataListView的单选对话框，使用时外部用对话框包裹
  Widget _buildDataListView(BuildContext context) {
    var dataListView = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          return DataListSingleSelect<String>(
            title: '',
            items: _buildOptions(),
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
