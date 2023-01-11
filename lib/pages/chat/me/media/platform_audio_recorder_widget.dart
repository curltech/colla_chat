import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

enum MediaRecorderType {
  record,
  another,
  waveform,
}

///平台标准的record的实现
class PlatformAudioRecorderWidget extends StatefulWidget with TileDataMixin {
  PlatformAudioRecorderWidget(
      {Key? key, AbstractAudioRecorderController? controller})
      : super(key: key);

  @override
  State createState() => _PlatformAudioRecorderWidgetState();

  @override
  String get routeName => 'audio_recorder';

  @override
  Icon get icon => const Icon(Icons.record_voice_over);

  @override
  String get title => 'AudioRecorder';

  @override
  bool get withLeading => true;
}

class _PlatformAudioRecorderWidgetState
    extends State<PlatformAudioRecorderWidget> {
  MediaRecorderType? mediaRecorderType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<AppBarPopupMenu>? _buildRightPopupMenus() {
    List<AppBarPopupMenu> menus = [];
    for (var type in MediaRecorderType.values) {
      AppBarPopupMenu menu = AppBarPopupMenu(
          title: type.name,
          onPressed: () {
            setState(() {
              mediaRecorderType = type;
              logger.i('mediaRecorderType:$type');
            });
          });
      menus.add(menu);
    }
    return menus;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: Text(AppLocalizations.t('AudioRecorder')),
      withLeading: true,
      rightPopupMenus: _buildRightPopupMenus(),
      child: PlatformAudioRecorder(
        height: 80,
        onStop: (String filename) {
          logger.i('record audio filename:$filename');
        },
        mediaRecorderType: mediaRecorderType,
      ),
    );
  }
}
