
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/poem/poem.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class PoemWidget extends StatefulWidget with TileDataMixin {
  const PoemWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PoemWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'poem';

  @override
  IconData get iconData => Icons.library_music_outlined;

  @override
  String get title => 'Poem';
}

class _PoemWidgetState extends State<PoemWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildParser(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle(
        maximumSize: const Size(140.0, 56.0), backgroundColor: myself.primary);
    return TextButton.icon(
      style: style,
      icon: const Icon(Icons.exit_to_app),
      label: CommonAutoSizeText(AppLocalizations.t('parse')),
      onPressed: () async {
        await poemService
            .parseJson('/Users/jingsonghu/Downloads/chinese-poetry-master');
        logger.i('parse json completely!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var personalInfo = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      child: _buildParser(context),
    );

    return personalInfo;
  }
}
