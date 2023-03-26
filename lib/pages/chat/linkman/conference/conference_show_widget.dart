import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> conferenceColumnFieldDefs = [
  ColumnFieldDef(
      name: 'conferenceId',
      label: 'ConferenceId',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.meeting_room, color: myself.primary)),
  ColumnFieldDef(
      name: 'name',
      label: 'Name',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.person, color: myself.primary)),
  ColumnFieldDef(
      name: 'topic',
      label: 'Topic',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.topic, color: myself.primary)),
  ColumnFieldDef(
      name: 'conferenceOwnerPeerId',
      label: 'ConferenceOwnerPeerId',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.perm_identity, color: myself.primary)),
  ColumnFieldDef(
      name: 'video',
      label: 'Video',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.video_call, color: myself.primary)),
  ColumnFieldDef(
      name: 'startDate',
      label: 'StartDate',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.start, color: myself.primary)),
  ColumnFieldDef(
      name: 'endDate',
      label: 'EndDate',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.pin_end, color: myself.primary)),
];

///显示会议的基本信息，会议成员和会议发起人
class ConferenceShowWidget extends StatelessWidget {
  final Conference conference;

  const ConferenceShowWidget({Key? key, required this.conference})
      : super(key: key);

  //当当前会议改变后，更新数据，局部刷新
  Future<List<Option<String>>> _buildConferenceOptions() async {
    List<Option<String>> options = <Option<String>>[];
    List<String> participants = conference.participants ?? [];
    for (String participant in participants) {
      var linkman = await linkmanService.findCachedOneByPeerId(participant);
      if (linkman != null) {
        options.add(
            Option(linkman.name, linkman.peerId, leading: linkman.avatarImage));
      }
    }
    return options;
  }

  //字段的数据使用控制器数据，直接修改，optionsChanged用于表示控制器数据改变了
  Widget _buildChips(BuildContext context) {
    return FutureBuilder(
        future: _buildConferenceOptions(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Option<String>>> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            var options = snapshot.data!;
            List<Chip> chips = [];
            for (var option in options) {
              var chip = Chip(
                label: Text(
                  option.label,
                  style: const TextStyle(color: Colors.black),
                ),
                avatar: option.leading,
                backgroundColor: Colors.white,
                deleteIconColor: myself.primary,
              );
              chips.add(chip);
            }
            if (chips.isNotEmpty) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: chips,
              );
            } else {
              return Container();
            }
          }
          return Container();
        });
  }

  //会议信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    Map<String, dynamic>? initValues = {};
    initValues = conferenceController.getInitValue(conferenceColumnFieldDefs,
        entity: conference);
    var formInputWidget = SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.all(10.0),
            child: FormInputWidget(
              height: 300,
              columnFieldDefs: conferenceColumnFieldDefs,
              initValues: initValues,
            )));

    return formInputWidget;
  }

  Future<List<TileData>> _buildChatReceipts() async {
    Map<String, Map<String, ChatMessage>> chatReceiptMap =
        await VideoChatMessageController.findChatReceipts(
            conference.conferenceId);
    List<TileData> tiles = [];
    for (var key in chatReceiptMap.keys) {
      var chatReceipts = chatReceiptMap[key];
      for (var chatReceipt in chatReceipts!.values) {
        Linkman? linkman = await linkmanService
            .findCachedOneByPeerId(chatReceipt.senderPeerId!);
        var tile = TileData(
            title: chatReceipt.senderName!,
            titleTail: key,
            prefix: linkman?.avatarImage);

        tiles.add(tile);
      }
    }
    return tiles;
  }

  Widget _buildConferenceShow(BuildContext context) {
    return Column(
      children: [
        _buildChips(context),
        const SizedBox(
          height: 5,
        ),
        _buildFormInputWidget(context),
        Expanded(
            child: FutureBuilder<List<TileData>>(
          future: _buildChatReceipts(),
          builder:
              (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return DataListView(
                tileData: snapshot.data!,
              );
            }
            return Container();
          },
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildConferenceShow(context);
  }
}
