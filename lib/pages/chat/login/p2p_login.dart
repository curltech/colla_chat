import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/pages/chat/login/p2p_login_widget.dart';
import 'package:colla_chat/pages/chat/login/p2p_register_widget.dart';
import 'package:colla_chat/pages/chat/login/p2p_setting_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatefulWidget {
  final P2pLoginWidget p2pLoginWidget = const P2pLoginWidget();
  final P2pRegisterWidget p2pRegisterWidget = const P2pRegisterWidget();
  final P2pSettingWidget p2pSettingWidget = const P2pSettingWidget();

  // final MyselfPeerViewWidget myselfPeerViewWidget =
  //     const MyselfPeerViewWidget();
  late final List<Widget> _children;
  late final SwiperController controller = SwiperController();

  P2pLogin({Key? key}) : super(key: key) {
    // 初始化子项集合
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
      p2pSettingWidget,
      // myselfPeerViewWidget,
    ];
  }

  @override
  State<StatefulWidget> createState() => _P2pLoginState();
}

class _P2pLoginState extends State<P2pLogin> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    myself.addListener(_update);
    appDataProvider.addListener(_update);
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  _animateToPage(int index) {
    widget.controller.move(index);
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var pageView = Swiper(
      controller: widget.controller,
      itemCount: widget._children.length,
      itemBuilder: (BuildContext context, int index) {
        return widget._children[index];
      },
      onIndexChanged: (int index) {
        this.index = index;
      },
      index: index,
    );
    var appBar = AppBarWidget.buildAppBar(
      context,
      title: CommonAutoSizeText(AppLocalizations.t('Login')),
      rightWidgets: [
        IconButton(
            onPressed: () {
              _animateToPage(0);
            },
            icon: const Icon(Icons.login, color: Colors.white),
            tooltip: AppLocalizations.t('Login')),
        IconButton(
          onPressed: () {
            _animateToPage(1);
          },
          icon: const Icon(Icons.app_registration, color: Colors.white),
          tooltip: AppLocalizations.t('Register'),
        ),
        IconButton(
          onPressed: () {
            _animateToPage(2);
          },
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: AppLocalizations.t('Setting'),
        ),
      ],
    );

    var workspace = Center(
        child: platformWidgetFactory.buildSizedBox(
      height: appDataProvider.actualSize.height,
      width: appDataProvider.actualSize.width,
      child: pageView,
    ));
    return Scaffold(
        appBar: appBar,
        body: KeyboardDismissOnTap(
            dismissOnCapturedTaps: false,
            child: Stack(children: <Widget>[
              Opacity(
                opacity: 1,
                child: loadingWidget,
              ),
              workspace
            ])));
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
