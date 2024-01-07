import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

ValueNotifier<String?> roomNameNotifier = ValueNotifier<String?>(null);

/// 创建参与者和管理参与者的界面
class LiveKitSfuParticipantWidget extends StatefulWidget with TileDataMixin {
  LiveKitSfuParticipantWidget({super.key});

  @override
  State<StatefulWidget> createState() => _LiveKitSfuParticipantWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_participant';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'SfuParticipant';
}

class _LiveKitSfuParticipantWidgetState
    extends State<LiveKitSfuParticipantWidget> with TickerProviderStateMixin {
  ValueNotifier<List<TileData>> tileData = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    _init();
  }

  _init() async {
    String? roomName = roomNameNotifier.value;
    if (roomName == null) {
      return;
    }
    List<LiveKitParticipant>? participants =
        await conferenceService.listSfuParticipants(roomName);
    List<TileData> tiles = [];
    if (participants != null && participants.isNotEmpty) {
      for (var participant in participants) {
        String? name = participant.name;
        String? identity = participant.identity;
        int? joinedAt = participant.joinedAt;
        TileData tile = TileData(
          title: name!,
          subtitle: identity.toString(),
          titleTail: joinedAt.toString(),
          selected: false,
        );

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
        title: roomNameNotifier.value,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: _buildSearchRoomView(context));
  }
}
