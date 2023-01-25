import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

enum SelectType {
  smartselect, //多选字段
  multiselect, //多选字段
  multidialog, //多选对话框
  listview, //单选对话框
}

///联系人和群的查询界面
class LinkmanGroupSearchWidget extends StatefulWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final bool searchable; //是否有搜索字段
  final SelectType
      selectType; //查询界面的类型，multi界面无搜索字段，dialog和listview可以包括在showDialog中
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
  List<String> selected = [];
  List<Linkman> linkmen = [];
  List<Group> groups = [];
  String title = '';
  String placeholder = '';

  @override
  initState() {
    super.initState();
    selected.addAll(widget.selected);
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

  Future<bool> _search() async {
    if (widget.includeLinkman) {
      linkmen = await linkmanService.search(textController.text);
    }
    if (widget.includeGroup) {
      groups = await groupService.search(textController.text);
    }
    logger.i('search complete');
    return true;
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
        labelText: AppLocalizations.t('Search') +
            AppLocalizations.t(' ') +
            AppLocalizations.t(title),
        suffixIcon: IconButton(
          onPressed: () async {
            await _search();
            setState(() {});
          },
          icon: const Icon(Icons.search),
        ),
      ),
    );

    return searchTextField;
  }

  List<Option<String>> _buildOptions() {
    List<Option<String>> options = [];
    if (widget.includeLinkman) {
      for (Linkman linkman in linkmen) {
        bool checked = selected.contains(linkman.peerId);
        Option<String> item =
            Option<String>(linkman.name, linkman.peerId, checked: checked);
        options.add(item);
      }
    }
    if (widget.includeGroup) {
      for (Group group in groups) {
        bool checked = selected.contains(group.peerId);
        Option<String> item =
            Option<String>(group.name, group.peerId, checked: checked);
        options.add(item);
      }
    }

    return options;
  }

  /// 一个搜索字段和一个多选字段的组合，选择项通过传入的回调方法返回
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
              this.selected = selected;
              widget.onSelected(selected);
            },
            items: options,
            modalFilter: true,
            modalFilterAuto: true,
            chipOnDelete: (i) {
              setState(() {
                selected.removeAt(i);
                widget.onSelected(selected);
              });
            },
          );
        });

    return selector;
  }

  /// 一个搜索字段和一个多选字段的组合，选择项通过传入的回调方法返回
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
              this.selected = selected;
              widget.onSelected(selected);
            },
            items: options,
          );
        });

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [_buildSearchTextField(context), selector]));
  }

  /// 一个搜索字段和一个多选字段的组合，对话框的形式，使用时外部用对话框包裹
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
              this.selected = selected;
              widget.onSelected(selected);
            },
            items: _buildOptions(),
          );
        });
    return selector;
  }

  //将linkman数据转换从列表显示数据
  List<TileData> _buildTileData() {
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name;
        var subtitle = linkman.peerId;
        TileData tile = TileData(
          prefix: linkman.avatar,
          title: title,
          subtitle: subtitle,
          dense: false,
        );
        tiles.add(tile);
      }
    }
    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    widget.onSelected([subtitle!]);
  }

  /// 一个搜索字段和一个单选选字段的组合，对话框的形式，使用时外部用对话框包裹
  Widget _buildDataListView(BuildContext context) {
    var dataListView = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          return DataListView(
            tileData: _buildTileData(),
            onTap: _onTap,
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
