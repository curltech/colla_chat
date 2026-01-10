import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_participant_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 创建房间和管理房间的界面
class LiveKitSfuRoomWidget extends StatelessWidget with TileDataMixin {
  LiveKitSfuRoomWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_room';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'SfuRoom';

  

  final Rx<List<TileData>> tileData = Rx<List<TileData>>([]);

  Future<void> _init() async {
    LiveKitManageRoom liveKitManageRoom = await conferenceService.listSfuRoom();
    List<LiveKitRoom>? rooms = liveKitManageRoom.rooms;
    List<TileData> tiles = [];
    if (rooms != null && rooms.isNotEmpty) {
      for (LiveKitRoom room in rooms) {
        String name = room.name ?? '';
        DateTime? creationTime = room.creationTime;
        Duration emptyTimeout = Duration(seconds: room.emptyTimeout ?? 0);
        LiveKitRoom current = room;
        TileData tile = TileData(
            title: name,
            subtitle: creationTime.toString(),
            titleTail: emptyTimeout.toString(),
            selected: false,
            onTap: (int index, String title, {String? subtitle}) {
              _showRoom(liveKitManageRoom, current);
            });
        tile.endSlideActions = [
          TileData(
              title: 'Delete',
              onTap: (int index, String title, {String? subtitle}) async {
                await conferenceService.deleteRoom(name);
                await _init();
              }),
          TileData(
              title: 'Participant',
              onTap: (int index, String title, {String? subtitle}) {
                roomName.value = name;
                indexWidgetProvider.push('sfu_participant');
              })
        ];

        tiles.add(tile);
      }
    }

    tileData.value = tiles;
  }

  void _showRoom(LiveKitManageRoom liveKitManageRoom, LiveKitRoom room) {
    DialogUtil.show(builder: (BuildContext context) {
      return Dialog(
          child: Container(
              width: appDataProvider.secondaryBodyWidth,
              height: 300,
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${AppLocalizations.t('host')}:${liveKitManageRoom.host ?? ''}'),
                  Text(
                      '${AppLocalizations.t('maxParticipants')}:${liveKitManageRoom.maxParticipants}'),
                  Text(
                      '${AppLocalizations.t('identities')}:${liveKitManageRoom.identities ?? []}'),
                  Text(
                      '${AppLocalizations.t('names')}:${liveKitManageRoom.names ?? []}'),
                  Text(
                      '${AppLocalizations.t('tokens')}:${liveKitManageRoom.tokens ?? []}'),
                  Text('${AppLocalizations.t('name')}:${room.name ?? ''}'),
                  Text(
                      '${AppLocalizations.t('creationTime')}:${room.creationTime?.toIso8601String() ?? ''}'),
                  Text(
                      '${AppLocalizations.t('turnPassword')}:${room.turnPassword ?? ''}'),
                  Text('${AppLocalizations.t('sid')}:${room.sid ?? ''}'),
                  Text(
                      '${AppLocalizations.t('emptyTimeout')}:${room.emptyTimeout?.toString() ?? ''}'),
                  Text(
                      '${AppLocalizations.t('enabledCodecs')}:${room.enabledCodecs ?? []}'),
                ],
              )));
    });
  }

  Future<void> _createRoom(String roomName) async {
    await conferenceService.createSfuRoom(roomName);
    await _init();
  }

  Widget _buildSearchRoomView(BuildContext context) {
    return Obx(() {
      return DataListView(
        itemCount: tileData.value.length,
        itemBuilder: (BuildContext context, int index) {
          return tileData.value[index];
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _init();
    List<Widget>? rightWidgets = [
      IconButton(
          tooltip: AppLocalizations.t('Add room'),
          onPressed: () async {
            String? roomName = await DialogUtil.showTextFormField(
                title: 'Add room', content: 'room name');
            if (roomName != null && roomName.isNotEmpty) {
              _createRoom(roomName);
            }
          },
          icon: const Icon(Icons.add)),
    ];
    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: _buildSearchRoomView(context));
  }
}
