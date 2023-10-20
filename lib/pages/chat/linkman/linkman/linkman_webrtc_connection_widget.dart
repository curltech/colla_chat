import 'package:badges/badges.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:badges/badges.dart' as badges;
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

final DataListController<Linkman> groupLinkmanController =
    DataListController<Linkman>();

/// 群或者会议中的联系人的信息和webrtc连接状态
class LinkmanWebrtcConnectionWidget extends StatefulWidget with TileDataMixin {
  const LinkmanWebrtcConnectionWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanWebrtcConnectionWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman_webrtc_connection';

  @override
  IconData get iconData => Icons.connecting_airports_outlined;

  @override
  String get title => 'Linkman webrtc connection';
}

class _LinkmanWebrtcConnectionWidgetState
    extends State<LinkmanWebrtcConnectionWidget> {
  @override
  initState() {
    groupLinkmanController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildBadge(int connectionNum, {Widget? avatarImage}) {
    var badge = avatarImage ?? AppImage.mdAppImage;
    badge = badges.Badge(
      position: BadgePosition.topEnd(),
      stackFit: StackFit.loose,
      badgeContent: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 12,
          ),
          child: Center(
              child: CommonAutoSizeText('$connectionNum',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)))),
      badgeStyle: badges.BadgeStyle(
        elevation: 0.0,
        badgeColor: connectionNum == 0 ? Colors.red : Colors.green,
        shape: badges.BadgeShape.square,
        borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(8), right: Radius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 2.0),
      ),
      child: badge,
    );

    return badge;
  }

  List<TileData> _buildConnectionTileData(BuildContext context) {
    List<Linkman> linkmen = groupLinkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var name = linkman.name;
        var peerId = linkman.peerId;
        Widget? prefix = linkman.avatarImage;
        String routeName = 'linkman_edit';
        prefix = prefix ?? AppImage.mdAppImage;
        int connectionNum = 0;
        List<AdvancedPeerConnection>? connections =
            peerConnectionPool.getConnected(peerId);
        if (connections != null && connections.isNotEmpty) {
          connectionNum = connections.length;
        }
        TileData tile = TileData(
            prefix: _buildBadge(connectionNum, avatarImage: prefix),
            title: name,
            subtitle: peerId,
            selected: false,
            routeName: routeName);
        tiles.add(tile);
      }
    }

    return tiles;
  }

  Widget _buildConnectionListView(BuildContext context) {
    var connectionView = DataListView(
      tileData: _buildConnectionTileData(context),
    );

    return connectionView;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: true,
      child: _buildConnectionListView(context),
    );
  }
}