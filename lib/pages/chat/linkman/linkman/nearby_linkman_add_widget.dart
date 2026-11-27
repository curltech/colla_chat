// import 'package:colla_chat/entity/chat/chat_message.dart';
// import 'package:colla_chat/entity/chat/linkman.dart';
// import 'package:colla_chat/entity/p2p/security_context.dart';
// import 'package:colla_chat/provider/data_list_controller.dart';
// import 'package:colla_chat/service/chat/linkman.dart';
// import 'package:colla_chat/transport/nearby_connection.dart';
// import 'package:colla_chat/widgets/common/app_bar_view.dart';
// import 'package:colla_chat/widgets/common/widget_mixin.dart';
// import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
// import 'package:colla_chat/widgets/data_bind/data_listview.dart';
// import 'package:flutter/material.dart';
//
// ///附近的人加联系人
// class NearbyLinkmanAddWidget extends StatefulWidget with TileDataMixin {
//   final DataListController<TileData> controller =
//       DataListController<TileData>();
//   late final DataListView dataListView;
//
//   NearbyLinkmanAddWidget({Key? key}) : super(key: key) {
//     dataListView = DataListView(
//       controller: controller,
//     );
//   }
//
//   @override
//   IconData get iconData => Icons.location_city;
//
//   @override
//   String get routeName => 'nearby_linkman_add';
//
//   @override
//   String get title => 'Nearby add linkman';
//
//   @override
//   bool get withLeading => true;
//
//   @override
//   State<StatefulWidget> createState() => _NearbyLinkmanAddWidgetState();
// }
//
// class _NearbyLinkmanAddWidgetState extends State<NearbyLinkmanAddWidget> {
//   var controller = TextEditingController();
//
//   @override
//   initState() {
//     super.initState();
//     widget.controller.addListener(_update);
//     nearbyConnectionPool.addListener(_update);
//     nearbyConnectionPool.search(DeviceType.advertiser);
//   }
//
//   _update() {
//     setState(() {});
//   }
//
//   _changeStatus(Linkman linkman, LinkmanStatus status) async {
//     int id = linkman.id!;
//     await linkmanService.update({'id': id, 'status': status.name});
//   }
//
//   Future<void> _transferTiles(BuildContext context) async {
//     List<TileData> tiles = [];
//     if (nearbyConnectionPool.nearbyConnections.isNotEmpty) {
//       for (var device in nearbyConnectionPool.nearbyConnections.values) {
//         var title = device.deviceName ?? '';
//         var subtitle = device.deviceId ?? '';
//         var connected = nearbyConnectionPool.connectedNearbyConnections
//             .containsKey(device.deviceId);
//         Widget suffix;
//         if (connected) {
//           suffix = IconButton(
//             iconSize: 24.0,
//             icon: const Icon(Icons.person_add),
//             onPressed: () async {
//               // 加好友会发送自己的信息，回执将收到对方的信息
//               // 没有对方的peerId和公钥，不加密
//               await linkmanService.addFriend(subtitle, '',
//                   transportType: TransportType.nearby,
//                   cryptoOption: CryptoOption.none);
//             },
//           );
//         } else {
//           suffix = IconButton(
//             iconSize: 24.0,
//             icon: const Icon(Icons.bluetooth_connected),
//             onPressed: () async {
//               await nearbyConnectionPool.invitePeer(device);
//             },
//           );
//         }
//         TileData tile =
//             TileData(title: title, subtitle: subtitle, suffix: suffix);
//         tiles.add(tile);
//       }
//     }
//     widget.controller.replaceAll(tiles);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AppBarView(
//         withLeading: true,
//         title: widget.title,
//         child: Column(children: [widget.dataListView]));
//   }
//
//   @override
//   void dispose() {
//     widget.controller.removeListener(_update);
//     nearbyConnectionPool.removeListener(_update);
//     controller.dispose();
//     super.dispose();
//   }
// }
