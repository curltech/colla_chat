import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///群的查询界面
class GroupSearchWidget extends StatefulWidget {
  //group的数据显示列表
  final DataListController<Group> groupController;

  const GroupSearchWidget({Key? key, required this.groupController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupSearchWidgetState();
}

class _GroupSearchWidgetState extends State<GroupSearchWidget> {
  @override
  initState() {
    super.initState();
    widget.groupController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  _search(String key) async {
    List<Group> group = await groupService.search(key);
    widget.groupController.replaceAll(group);
  }

  _buildSearchTextField(BuildContext context) {
    var controller = TextEditingController();
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.black.withOpacity(0.1),
              filled: true,
              border: InputBorder.none,
              labelText: AppLocalizations.t('Search'),
              suffixIcon: IconButton(
                onPressed: () {
                  _search(controller.text);
                },
                icon: const Icon(Icons.search),
              ),
            )));

    return searchTextField;
  }

  //将linkman数据转换从列表显示数据
  List<TileData> _buildGroupDataListController() {
    var groups = widget.groupController.data;
    List<TileData> tiles = [];
    if (groups.isNotEmpty) {
      for (var group in groups) {
        var title = group.name;
        var subtitle = group.peerId;
        TileData tile = TileData(
          prefix: group.avatar,
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
    widget.groupController.currentIndex = index;
    //Navigator.pop(context, subtitle);
  }

  @override
  Widget build(BuildContext context) {
    var groupDataListView = Container(
        padding: const EdgeInsets.all(10.0),
        child: DataListView(
          tileData: _buildGroupDataListController(),
          onTap: _onTap,
        ));
    return Column(children: [
      _buildSearchTextField(context),
      Expanded(child: groupDataListView)
    ]);
  }

  @override
  void dispose() {
    widget.groupController.removeListener(_update);
    super.dispose();
  }
}
