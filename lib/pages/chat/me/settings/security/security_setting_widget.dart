import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/color_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 安全设置组件，包括修改密码，登录选项，加密选项
class SecuritySettingWidget extends StatefulWidget with TileDataMixin {
  const SecuritySettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SecuritySettingWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'security_setting';

  @override
  Icon get icon => const Icon(Icons.security);

  @override
  String get title => 'Security Setting';
}

class _SecuritySettingWidgetState extends State<SecuritySettingWidget> {
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
        title: Text(AppLocalizations.t(widget.title)),
        child: _buildSettingWidget(context));
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
