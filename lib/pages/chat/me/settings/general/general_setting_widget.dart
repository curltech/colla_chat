import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/base/color_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 一般设置组件，包括颜色，亮度，语言
class GeneralSettingWidget extends StatelessWidget with TileDataMixin {
  const GeneralSettingWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'general_setting';

  @override
  IconData get iconData => Icons.settings_applications;

  @override
  String get title => 'General Setting';

  Widget _buildSettingWidget(BuildContext context) {
    return ListenableBuilder(
      listenable: appDataProvider,
      builder: (BuildContext context, Widget? child) {
        var padding = const EdgeInsets.symmetric(horizontal: 15.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30.0),
            Padding(
              padding: padding,
              child: const LocalePicker(),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: padding,
              child: ColorPicker(
                label: 'Seed color',
                onColorChanged: (Color color) {
                  myself.primaryColor = color;
                },
                initColor: myself.primaryColor,
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: padding,
              child: const BrightnessPicker(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true, title: title, child: _buildSettingWidget(context));
  }
}
