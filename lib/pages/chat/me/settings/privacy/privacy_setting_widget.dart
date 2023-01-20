import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/color_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 隐私设置组件，包括颜色，亮度，语言
class PrivacySettingWidget extends StatefulWidget with TileDataMixin {
  const PrivacySettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrivacySettingWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'privacy_setting';

  @override
  Icon get icon => const Icon(Icons.privacy_tip);

  @override
  String get title => 'Privacy Setting';
}

class _PrivacySettingWidgetState extends State<PrivacySettingWidget> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildSettingWidget(BuildContext context) {
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
          child: const ColorPicker(),
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: padding,
          child: const BrightnessPicker(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: _buildSettingWidget(context));
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
