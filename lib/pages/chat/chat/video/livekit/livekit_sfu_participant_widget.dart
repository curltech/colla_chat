import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<String?> roomName = Rx<String?>(null);

/// 创建参与者和管理参与者的界面
class LiveKitSfuParticipantWidget extends StatelessWidget with TileDataMixin {
  LiveKitSfuParticipantWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_participant';

  @override
  IconData get iconData => Icons.playlist_add;

  @override
  String get title => 'SfuParticipant';

  

  final RxList<TileData> tileData = <TileData>[].obs;

  Future<void> _init() async {
    if (roomName.value == null) {
      return;
    }
    List<LiveKitParticipant>? participants =
        await conferenceService.listSfuParticipants(roomName.value!);
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

  Widget _buildSearchRoomView(BuildContext context) {
    return DataListView(
      itemCount: tileData.value.length,
      itemBuilder: (BuildContext context, int index) {
        return tileData.value[index];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AppBarView(
          title: roomName.value,
          helpPath: routeName,
          withLeading: true,
          child: _buildSearchRoomView(context));
    });
  }
}
