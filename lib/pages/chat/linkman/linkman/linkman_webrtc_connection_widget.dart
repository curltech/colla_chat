import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_edit_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

final DataListController<Linkman> groupLinkmanController =
    DataListController<Linkman>();

/// 群或者会议中的联系人的信息和webrtc连接状态
class LinkmanWebrtcConnectionWidget extends StatelessWidget with TileDataMixin {
  LinkmanWebrtcConnectionWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman_webrtc_connection';

  @override
  IconData get iconData => Icons.connecting_airports_outlined;

  @override
  String get title => 'Linkman webrtc connection';

  final ValueNotifier<List<TileData>> tileData =
      ValueNotifier<List<TileData>>([]);

  Widget _buildBadge(int connectionNum, {Widget? avatarImage}) {
    var badge = avatarImage ?? AppImage.mdAppImage;
    badge = Badge(
      backgroundColor: connectionNum == 0 ? Colors.red : Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 2.0),
      label: Center(
          child: CommonAutoSizeText('$connectionNum',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white))),
      child: badge,
    );

    return badge;
  }

  Future<List<TileData>> _buildConnectionTileData(BuildContext context) async {
    RxList<Linkman> linkmen = groupLinkmanController.data;
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var name = linkman.name;
        var peerId = linkman.peerId;
        Widget? prefix = linkman.avatarImage;
        String routeName = 'linkman_edit';
        prefix = prefix ?? AppImage.mdAppImage;
        int connectionNum = 0;
        RTCDataChannelState? dataChannelState =
            RTCDataChannelState.RTCDataChannelClosed;
        List<AdvancedPeerConnection> connections =
            await peerConnectionPool.get(peerId);
        if (connections.isNotEmpty) {
          connectionNum = connections.length;
          dataChannelState = connections.first.dataChannelState;
        }
        TileData tile = TileData(
            prefix: _buildBadge(connectionNum, avatarImage: prefix),
            title: name,
            subtitle: peerId,
            titleTail: dataChannelState?.name.substring(14),
            selected: false,
            routeName: routeName,
            onTap: (int index, String title, {String? subtitle}) {
              linkmanNotifier.value = linkman;
            });
        tiles.add(tile);
      }
    }

    return tiles;
  }

  Widget _buildConnectionListView(BuildContext context) {
    var connectionView = Obx(() {
      return PlatformFutureBuilder(
        future: _buildConnectionTileData(context),
        builder: (BuildContext context, List<TileData> tileData) {
          return DataListView(
            itemCount: tileData.length,
            itemBuilder: (BuildContext context, int index) {
              return tileData[index];
            },
          );
        },
      );
    });

    return connectionView;
  }

  @override
  Widget build(BuildContext context) {
    _buildConnectionTileData(context);
    return AppBarView(
      title: title,
      withLeading: true,
      child: _buildConnectionListView(context),
    );
  }
}
