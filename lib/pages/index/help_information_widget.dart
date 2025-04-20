import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/index/index_view.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:colla_chat/plugin/talker_logger.dart';

class HelpInformationController {
  RxString title = ''.obs;
  String _helpPath = '';
  RxString information = ''.obs;

  String get helpPath {
    return _helpPath;
  }

  set helpPath(String helpPath) {
    _helpPath = helpPath;
    _loadString();
  }

  _loadString() async {
    String languageCode = myself.locale.languageCode;

    try {
      String path;
      if (languageCode == 'en') {
        path = 'assets/$helpPath.md';
      } else {
        path = 'assets/markdown/${helpPath}_$languageCode.md';
      }
      information.value = await rootBundle.loadString(path);
    } catch (e) {
      logger.e('load help information:$helpPath failure:$e');
      information.value = '';
    }
  }
}

final HelpInformationController helpInformationController =
    HelpInformationController();

// 帮助信息页面
class HelpInformationWidget extends StatelessWidget  with TileDataMixin {
  const HelpInformationWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'help';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Help information';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String information = helpInformationController.information.value;
      return AppBarView(
          title:
              '${helpInformationController.title.value} ${AppLocalizations.t('help')}',
          withLeading: true,
          child: Container(
              color: Colors.white.withAlpha(0),
              child: GptMarkdown(information)));
    });
  }
}
