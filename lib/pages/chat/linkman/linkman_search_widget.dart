import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

enum SelectType { smartselect, multiselect, multidialog, listview }

///联系人的查询界面
class LinkmanSearchWidget extends StatefulWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final bool searchable; //是否有搜索字段
  final SelectType
      selectType; //查询界面的类型，multi界面无搜索字段，dialog和listview可以包括在showDialog中

  const LinkmanSearchWidget(
      {Key? key,
      required this.onSelected,
      required this.selected,
      this.searchable = true,
      this.selectType = SelectType.smartselect})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanSearchWidgetState();
}

class _LinkmanSearchWidgetState extends State<LinkmanSearchWidget> {
  TextEditingController textController = TextEditingController();
  List<String> selected = [];
  List<Linkman> linkmen = [];

  @override
  initState() {
    super.initState();
    selected.addAll(widget.selected);
  }

  Future<List<Linkman>> _search() async {
    linkmen = await linkmanService.search(textController.text);
    logger.i('search complete');

    return linkmen;
  }

  Widget _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
      autofocus: true,
      controller: textController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        fillColor: Colors.white.withOpacity(0.5),
        filled: true,
        border: InputBorder.none,
        labelText: AppLocalizations.t('Search linkman'),
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
    for (Linkman linkman in linkmen) {
      bool checked = selected.contains(linkman.peerId);
      Option<String> item =
          Option<String>(linkman.name, linkman.peerId, checked: checked);
      options.add(item);
    }

    return options;
  }

  //群成员显示和编辑界面
  Widget _buildSmartSelectWidget(BuildContext context) {
    var selector = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          var options = _buildOptions();
          return SmartSelectUtil.multiple<String>(
            title: 'Linkman',
            placeholder: 'Select more linkmen',
            leading: widget.searchable
                ? SizedBox(
                    width: 200,
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
              selected.removeAt(i);
              widget.onSelected(selected);
              setState(() {});
            },
          );
        });

    return selector;
  }

  Widget _buildMultiSelectWidget(BuildContext context) {
    var selector = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          var options = _buildOptions();
          return MultiSelectUtil.buildMultiSelectDialogField<String>(
            title: 'Linkman',
            buttonText: 'Linkman',
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

  Widget _buildMultiSelectDialog(BuildContext context) {
    var selector = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          var hasData = snapshot.hasData;
          if (hasData) {
            return MultiSelectUtil.buildMultiSelectDialog<String>(
              title: 'Linkman',
              onConfirm: (selected) {
                this.selected = selected;
                widget.onSelected(selected);
              },
              items: _buildOptions(),
            );
          } else {
            return Container();
          }
        });
    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          _buildSearchTextField(context),
          Expanded(child: selector)
        ]));
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

  Widget _buildDataListView(BuildContext context) {
    var dataListView = FutureBuilder(
        future: _search(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
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
