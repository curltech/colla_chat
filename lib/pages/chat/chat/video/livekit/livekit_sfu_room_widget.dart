import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_participant_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 创建房间和管理房间的界面
class LiveKitSfuRoomWidget extends StatefulWidget with TileDataMixin {
  LiveKitSfuRoomWidget({super.key});

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
    List<LiveKitRoom>? rooms = await conferenceService.listSfuRoom();
    List<TileData> tiles = [];
    if (rooms != null && rooms.isNotEmpty) {
      for (var room in rooms) {
        String name = room.name ?? '';
        DateTime? creationTime = room.creationTime;
        Duration emptyTimeout = Duration(seconds: room.emptyTimeout ?? 0);
        TileData tile = TileData(
          title: name,
          subtitle: creationTime.toString(),
          titleTail: emptyTimeout.toString(),
          selected: false,
        );
        tile.endSlideActions = [
          TileData(
              title: 'Delete',
              onTap: (int index, String title, {String? subtitle}) {
                conferenceService.deleteRoom(name);
                _init();
              }),
          TileData(
              title: 'Add participant',
              onTap: (int index, String title, {String? subtitle}) {}),
          TileData(
              title: 'Participant',
              onTap: (int index, String title, {String? subtitle}) {
                roomNameNotifier.value = name;
                indexWidgetProvider.push('sfu_participant');
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
