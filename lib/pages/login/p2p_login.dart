import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/login/loading.dart';
import 'package:colla_chat/pages/login/p2p_login_widget.dart';
import 'package:colla_chat/pages/login/p2p_register_widget.dart';
import 'package:colla_chat/pages/login/p2p_setting_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatefulWidget {
  final SwiperController swiperController = SwiperController();
  final P2pLoginWidget p2pLoginWidget = const P2pLoginWidget();
  late final P2pRegisterWidget p2pRegisterWidget = P2pRegisterWidget(
    swiperController: swiperController,
  );
  late final P2pSettingWidget p2pSettingWidget = P2pSettingWidget(
    swiperController: swiperController,
  );

  // final MyselfPeerViewWidget myselfPeerViewWidget =
  //     const MyselfPeerViewWidget();
  late final List<Widget> _children;

  P2pLogin({super.key}) {
    // 初始化子项集合
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
      p2pSettingWidget,
      // myselfPeerViewWidget,
    ];
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
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
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
    if (myselfPeers.isEmpty) {
      index = 1;
    }
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  _animateToPage(int index) {
    widget.swiperController.move(index);
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var pageView = Swiper(
      controller: widget.swiperController,
      itemCount: widget._children.length,
      itemBuilder: (BuildContext context, int index) {
        return widget._children[index];
      },
      onIndexChanged: (int index) {
        setState(() {
          this.index = index;
        });
      },
      index: index,
    );
    List<Widget> rightWidgets = [];
    if (index != 0) {
      rightWidgets.addAll([
        IconTextButton(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          onPressed: () {
            _animateToPage(0);
          },
          icon: const Icon(Icons.login, color: Colors.white),
          label: AppLocalizations.t('Login'),
          labelColor: Colors.white,
        ),
        const SizedBox(
          width: 10.0,
        ),
      ]);
    }
    if (index != 1) {
      rightWidgets.addAll([
        IconTextButton(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          onPressed: () {
            _animateToPage(1);
          },
          icon: const Icon(Icons.app_registration, color: Colors.white),
          label: AppLocalizations.t('Register'),
          labelColor: Colors.white,
        ),
        const SizedBox(
          width: 10.0,
        ),
      ]);
    }
    if (index != 2) {
      rightWidgets.add(
        IconTextButton(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          onPressed: () {
            _animateToPage(2);
          },
          icon: const Icon(Icons.settings, color: Colors.white),
          label: AppLocalizations.t('Setting'),
          labelColor: Colors.white,
        ),
      );
    }
    PreferredSizeWidget appBar = AppBarWidget.buildAppBar(
      context,
      title: CommonAutoSizeText(AppLocalizations.t('Login')),
      rightWidgets: rightWidgets,
    );

    var workspace = Center(
        child: platformWidgetFactory.sizedBox(
      height: appDataProvider.portraitSize.height,
      width: appDataProvider.portraitSize.width,
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
