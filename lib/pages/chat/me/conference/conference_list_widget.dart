import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/conference/conference_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/conference/video_conference_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

final DataListController<Conference> conferenceController =
    DataListController<Conference>();

///联系人和群的查询界面
class ConferenceListWidget extends StatefulWidget with TileDataMixin {
  final ConferenceEditWidget conferenceEditWidget = ConferenceEditWidget();
  final VideoConferenceWidget videoConferenceWidget =
      const VideoConferenceWidget();

  late final List<TileData> meTileData;

  ConferenceListWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(conferenceEditWidget);
    List<TileDataMixin> mixins = [conferenceEditWidget, videoConferenceWidget];
    meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = true;
      tile.selected = false;
    }
  }

  @override
  State<StatefulWidget> createState() => _ConferenceListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'conference';

  @override
  IconData get iconData => Icons.meeting_room;

  @override
  String get title => 'Conference';
}

class _ConferenceListWidgetState extends State<ConferenceListWidget>
    with TickerProviderStateMixin {
  final TextEditingController _conferenceTextController =
      TextEditingController();
  final ValueNotifier<List<TileData>> _conferenceTileData =
      ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    _searchConference(_conferenceTextController.text);
  }

  _updateConference() {
    _buildConferenceTileData();
  }

  _searchConference(String key) async {
    List<Conference> conference = await conferenceService.search(key);
    List<Conference> cs = [];
    if (conference.isNotEmpty) {
      for (var conference in conference) {
        Conference? c = await conferenceService
            .findCachedOneByConferenceId(conference.conferenceId);
        if (c != null) {
          cs.add(c);
        }
      }
    }
    conferenceController.replaceAll(cs);
  }

  _buildConferenceSearchTextField(BuildContext context) {
    var searchTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            autofocus: true,
            controller: _conferenceTextController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
              filled: true,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              //labelText: AppLocalizations.t('Search'),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchConference(_conferenceTextController.text);
                },
                icon: Icon(
                  Icons.search,
                  color: myself.primary,
                ),
              ),
            )));

    return searchTextField;
  }

  _changeStatus(Conference conference, EntityStatus status) async {
    int id = conference.id!;
    await conferenceService.update({'id': id, 'status': status.name});
  }

  _changeSubscriptStatus(Conference conference, EntityStatus status) async {
    int id = conference.id!;
    await conferenceService.update({'id': id, 'subscriptStatus': status.name});
  }

  //将Conference数据转换从列表显示数据
  _buildConferenceTileData() {
    var conferences = conferenceController.data;
    List<TileData> tiles = [];
    if (conferences.isNotEmpty) {
      for (var conference in conferences) {
        var name = conference.name;
        var conferenceId = conference.conferenceId;
        TileData tile = TileData(
            title: name!,
            subtitle: conferenceId,
            selected: false,
            routeName: 'conference_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              conferenceController.currentIndex = index;
              await conferenceService.removeByConferenceId(subtitle!);
              conferenceController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData chatSlideAction = TileData(
            title: 'VideoConference',
            prefix: Icons.video_call,
            onTap: (int index, String label, {String? subtitle}) async {
              conferenceController.currentIndex = index;
              indexWidgetProvider.push('video_conference');
            });
        slideActions.add(chatSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        if (conference.status == EntityStatus.subscript.name) {
          endSlideActions.add(
            TileData(
                title: 'Remove subscript',
                prefix: Icons.unsubscribe,
                onTap: (int index, String title, {String? subtitle}) {
                  _changeSubscriptStatus(conference, EntityStatus.effective);
                }),
          );
        } else {
          endSlideActions.add(TileData(
              title: 'Add subscript',
              prefix: Icons.subscriptions,
              onTap: (int index, String title, {String? subtitle}) {
                _changeSubscriptStatus(conference, EntityStatus.subscript);
              }));
        }
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    _conferenceTileData.value = tiles;
  }

  Widget _buildConferenceListView(BuildContext context) {
    var conferenceView = Column(children: [
      _buildConferenceSearchTextField(context),
      Expanded(
          child: ValueListenableBuilder(
              valueListenable: _conferenceTileData,
              builder: (context, value, child) {
                return DataListView(
                  tileData: value,
                  onTap: (int index, String title,
                      {TileData? group, String? subtitle}) {},
                );
              }))
    ]);

    return conferenceView;
  }

  @override
  Widget build(BuildContext context) {
    var rightWidgets = [
      IconButton(
          onPressed: () {
            conferenceController.currentIndex = -1;
            indexWidgetProvider.push('conference_edit');
          },
          icon: const Icon(Icons.add_business, color: Colors.white),
          tooltip: AppLocalizations.t('Add conference')),
    ];
    return AppBarView(
        title: widget.title,
        rightWidgets: rightWidgets,
        child: _buildConferenceListView(context));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
