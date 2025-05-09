import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

class LinkmanInfoWidget extends StatefulWidget with TileDataMixin {
  const LinkmanInfoWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LinkmanInfoWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman_info';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Linkman Information';

  
}

class _LinkmanInfoWidgetState extends State<LinkmanInfoWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Linkman? linkman = linkmanController.current;
    Widget linkmanInfo = nilBox;
    if (linkman != null) {
      String name = linkman.name;
      var peerId = linkman.peerId;
      final List<TileData> linkmanInfoTileData = [
        TileData(
          title: 'Avatar',
          suffix: linkman.avatarImage,
        ),
        TileData(
          title: 'PeerId',
          subtitle: peerId,
        ),
        TileData(
          title: 'Name',
          suffix: name,
        ),
        TileData(
          title: 'Email',
          suffix: linkman.email,
        ),
        TileData(
          title: 'Mobile',
          suffix: linkman.mobile,
        ),
      ];

      linkmanInfo = AppBarView(
          title: widget.title,
          helpPath: widget.routeName,
          withLeading: widget.withLeading,
          child: DataListView(
            itemCount: linkmanInfoTileData.length,
            itemBuilder: (BuildContext context, int index) {
              return linkmanInfoTileData[index];
            },
          ));
    }

    return linkmanInfo;
  }
}
