import 'package:colla_chat/pages/chat/chat/video/livekit/widget/livekit_sfu_participant_widget.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 创建房间和管理房间的界面
class LiveKitSfuRoomWidget extends StatefulWidget with TileDataMixin {
  LiveKitSfuRoomWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LiveKitSfuRoomWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_room';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'SfuRoom';
}

class _LiveKitSfuRoomWidgetState extends State<LiveKitSfuRoomWidget>
    with TickerProviderStateMixin {
  ValueNotifier<List<TileData>> tileData = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    _init();
  }

  _init() async {
    LiveKitManageRoom liveKitManageRoom = await conferenceService.listSfuRoom();
    List<TileData> tiles = [];
    List<LiveKitRoom>? rooms = liveKitManageRoom.rooms;
    if (rooms != null && rooms.isNotEmpty) {
      for (var room in rooms) {
        String? name = room.name;
        DateTime? creationTime = room.creationTime;
        int? emptyTimeout = room.emptyTimeout;
        TileData tile = TileData(
          title: name!,
          subtitle: creationTime.toString(),
          titleTail: emptyTimeout.toString(),
          selected: false,
        );
        tile.endSlideActions = [
          TileData(
              title: 'Add participant',
              onTap: (int index, String title, {String? subtitle}) {}),
          TileData(
              title: 'Participant',
              onTap: (int index, String title, {String? subtitle}) {
                final LiveKitSfuParticipantWidget liveKitSfuParticipantWidget =
                    LiveKitSfuParticipantWidget(
                  roomName: name,
                );
              })
        ];

        tiles.add(tile);
      }
    }

    tileData.value = tiles;
  }

  _createRoom(String roomName) async {
    conferenceService.createSfuRoom(roomName);
  }

  Widget _buildSearchRoomView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: tileData,
        builder: (BuildContext context, List<TileData> value, Widget? child) {
          return DataListView(tileData: value);
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () async {
            String? roomName = await DialogUtil.showTextFormField(context,
                title: 'Add room', content: 'roomName');
            if (roomName != null && roomName.isNotEmpty) {
              _createRoom(roomName);
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
}
