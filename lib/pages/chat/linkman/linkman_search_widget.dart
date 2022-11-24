import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_info_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_info_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

import '../../../widgets/data_bind/base.dart';

///联系人的查询界面
class LinkmanSearchWidget extends StatefulWidget {
  //linkman的数据显示列表
  final DataListController<Linkman> linkmanController =
      DataListController<Linkman>();
  final Function(List<String>) onSelected;
  final List<String> selected;

  LinkmanSearchWidget(
      {Key? key, required this.onSelected, required this.selected})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanSearchWidgetState();
}

class _LinkmanSearchWidgetState extends State<LinkmanSearchWidget> {
  TextEditingController textController = TextEditingController();
  List<String> selected = [];

  @override
  initState() {
    super.initState();
    widget.linkmanController.addListener(_update);
    selected.addAll(widget.selected);
  }

  _update() {
    setState(() {});
  }

  Future<void> _search(String key) async {
    List<Linkman> linkmen = await linkmanService.search(key);
    widget.linkmanController.replaceAll(linkmen);
    setState(() {});
  }

  Widget _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
      autofocus: true,
      controller: textController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        fillColor: Colors.black.withOpacity(0.1),
        filled: true,
        border: InputBorder.none,
        labelText: AppLocalizations.t('Search'),
        suffixIcon: IconButton(
          onPressed: () async {
            await _search(textController.text);
          },
          icon: const Icon(Icons.search),
        ),
      ),
    );

    return searchTextField;
  }

  //群成员显示和编辑界面
  Widget _buildSmartSelectWidget(BuildContext context) {
    List<Linkman> linkmen = widget.linkmanController.data;
    List<Option<String>> choiceItems = [];
    for (Linkman linkman in linkmen) {
      bool checked = selected.contains(linkman.peerId);
      Option<String> item =
          Option<String>(linkman.name, linkman.peerId, checked: checked);
      choiceItems.add(item);
    }
    var selector = SmartSelectUtil.multiple<String>(
      title: 'Linkman',
      placeholder: 'Select more linkmen',
      leading: SizedBox(
        width: 240,
        child: _buildSearchTextField(context),
      ),
      onChange: (selected) {
        this.selected = selected;
        widget.onSelected(selected);
      },
      items: choiceItems,
      modalFilter: true,
      modalFilterAuto: true,
      chipOnDelete: (i) {
        selected.removeAt(i);
        widget.onSelected(selected);
        setState(() {});
      },
    );

    return selector;
  }

  Widget _buildMultiSelectWidget(BuildContext context) {
    List<Linkman> linkmen = widget.linkmanController.data;
    List<Option<String>> choiceItems = [];
    for (Linkman linkman in linkmen) {
      bool checked = selected.contains(linkman.peerId);
      Option<String> item =
          Option<String>(linkman.name, linkman.peerId, checked: checked);
      choiceItems.add(item);
    }
    var selector = MultiSelectUtil.buildMultiSelectDialogField<String>(
      title: 'Linkman',
      buttonText: const Text('Linkman'),
      onConfirm: (selected) {
        this.selected = selected;
        widget.onSelected(selected);
      },
      items: choiceItems,
    );
    Widget leading = SizedBox(
      child: _buildSearchTextField(context),
    );

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [leading, selector]));
  }

  //将linkman数据转换从列表显示数据
  List<TileData> _buildTileData() {
    var linkmen = widget.linkmanController.data;
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
    widget.linkmanController.currentIndex = index;
    widget.onSelected([widget.linkmanController.current!.peerId]);
  }

  Widget _buildDataListView(BuildContext context) {
    var dataListView = Container(
        padding: const EdgeInsets.all(10.0),
        child: DataListView(
          tileData: _buildTileData(),
          onTap: _onTap,
        ));
    return Column(children: [
      _buildSearchTextField(context),
      Expanded(child: dataListView)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildMultiSelectWidget(context);
  }

  @override
  void dispose() {
    widget.linkmanController.removeListener(_update);
    textController.dispose();
    super.dispose();
  }
}
