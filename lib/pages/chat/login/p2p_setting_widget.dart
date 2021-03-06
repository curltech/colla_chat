import 'package:colla_chat/widgets/setting/locale_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import '../../../widgets/setting/brightness_picker.dart';
import '../../../widgets/setting/ws_address_picker.dart';
import '../../../widgets/style/platform_widget_factory.dart';

/// 地址语言选择设置组件，一个card下的录入框和按钮组合
class P2pSettingWidget extends StatefulWidget {
  const P2pSettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pSettingWidgetState();
}

class _P2pSettingWidgetState extends State<P2pSettingWidget>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Provider.of<AppDataProvider>(context).locale;
    Provider.of<AppDataProvider>(context).themeData;
    Provider.of<AppDataProvider>(context).brightness;
    return platformWidgetFactory.buildContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const <Widget>[
          SizedBox(height: 30.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: LocalePicker(),
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: WsAddressPicker(),
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: BrightnessPicker(),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
