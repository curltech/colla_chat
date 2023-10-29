import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/livekit/livekit_conference_service_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:livekit_server_sdk/src/proto/livekit_models.pb.dart';
import 'package:fixnum/fixnum.dart';

/// sfu房间的查询结果控制器
final DataListController<Room> searchRoomController =
    DataListController<Room>();

/// 创建房间和管理房间的界面
class ServiceClientWidget extends StatefulWidget with TileDataMixin {
  ServiceClientWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ServiceClientWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'service_client';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'ServiceClient';
}

class _ServiceClientWidgetState extends State<ServiceClientWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchTextController = TextEditingController();
  ValueNotifier<List<TileData>> tileData = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    searchRoomController.clear();
    searchRoomController.addListener(_updateRoom);
  }

  _updateRoom() {
    _buildRoomTileData();
  }

  _buildRoomTileData() async {
    List<Room> rooms = searchRoomController.data;
    List<TileData> tiles = [];
    if (rooms.isNotEmpty) {
      for (var room in rooms) {
        var name = room.name;
        Int64 creationTime = room.creationTime;
        int maxParticipants = room.maxParticipants;
        TileData tile = TileData(
          title: name,
          subtitle: creationTime.toString(),
          titleTail: maxParticipants.toString(),
          selected: false,
        );
        tile.endSlideActions = [
          TileData(
              title: 'Add participant',
              onTap: (int index, String title, {String? subtitle}) {})
        ];

        tiles.add(tile);
      }
    }

    tileData.value = tiles;
  }

  _searchRoom(String keyword) async {
    LiveKitConferenceServiceClient client =
        liveKitConferenceServiceClientPool.createServiceClient();
    List<Room> rooms;
    if (keyword.isNotEmpty) {
      rooms = await client.listRooms([keyword]);
    } else {
      rooms = await client.listRooms(null);
    }

    searchRoomController.replaceAll(rooms);
  }

  Widget _buildSearchRoomView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          child: CommonAutoSizeTextFormField(
            controller: _searchTextController,
            keyboardType: TextInputType.text,
            suffixIcon: IconButton(
              onPressed: () {
                _searchRoom(_searchTextController.text);
              },
              icon: Icon(
                Icons.search,
                color: myself.primary,
              ),
            ),
          )),
      Expanded(
          child: ValueListenableBuilder(
              valueListenable: tileData,
              builder:
                  (BuildContext context, List<TileData> value, Widget? child) {
                return DataListView(tileData: value);
              })),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () async {
            String? roomName = await DialogUtil.showTextFormField(context,
                title: 'Add room', content: 'roomName');
            if (roomName != null && roomName.isNotEmpty) {
              LiveKitConferenceServiceClient client =
                  liveKitConferenceServiceClientPool.createServiceClient();
              Room room = await client.createRoom(roomName: roomName);
              searchRoomController.add(room);
            }
          },
          icon: const Icon(Icons.add)),
    ];
    return AppBarView(
        title: widget.title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: _buildSearchRoomView(context));
  }

  @override
  void dispose() {
    searchRoomController.removeListener(_updateRoom);
    super.dispose();
  }
}
