import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/pages/login/background.dart';
import 'package:colla_chat/pages/login/p2p_login_widget.dart';
import 'package:colla_chat/pages/login/p2p_register_widget.dart';
import 'package:colla_chat/pages/login/p2p_setting_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/button_widget.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatelessWidget with WindowListener {
  final PlatformCarouselController controller = PlatformCarouselController();
  final P2pLoginWidget p2pLoginWidget = P2pLoginWidget();
  late final P2pRegisterWidget p2pRegisterWidget = P2pRegisterWidget(
    controller: controller,
  );
  late final P2pSettingWidget p2pSettingWidget = const P2pSettingWidget();
  late final List<Widget> _children;

  P2pLogin({super.key}) {
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
      p2pSettingWidget,
    ];
    init();
  }

  final RxInt index = 0.obs;

  void init() async {
    await myselfPeerController.init();
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
    if (myselfPeers.isEmpty) {
      index.value = 1;
    }
  }

  @override
  onWindowResized() {
    appDataProvider.changeWindowSize();
  }

  void _animateToPage(int index) {
    controller.move(index);
  }

  Widget _buildRightWidget(BuildContext context) {
    return Obx(() {
      List<Widget> rightWidgets = [];
      if (index.value != 0) {
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
      if (index.value != 1) {
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
      if (index.value != 2) {
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

      return OverflowBar(
        children: rightWidgets,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.context = context;
    if (appDataProvider.bodyWidth == -1) {
      appDataProvider.calBodyWidth();
    }
    AnimatedBuilder;
    AnimatedContainer;
    var workspace = ListenableBuilder(
      listenable: appDataProvider,
      builder: (BuildContext context, Widget? child) {
        var pageView = Obx(() {
          return PlatformCarouselWidget(
            controller: controller,
            itemCount: _children.length,
            itemBuilder: (BuildContext context, int index, {int? realIndex}) {
              return _children[index];
            },
            onPageChanged: (int index,
                {PlatformSwiperDirection? direction,
                int? oldIndex,
                CarouselPageChangedReason? reason}) {
              this.index(index);
            },
            initialPage: index.value,
          );
        });
        return Center(
            child: pageView.asStyle(
          height: appDataProvider.portraitSize.height,
          width: appDataProvider.portraitSize.width,
        ));
      },
    );

    return ListenableBuilder(
        listenable: myself,
        builder: (BuildContext context, Widget? child) {
          PreferredSizeWidget appBar = AppBarWidget(
            title: AutoSizeText(AppLocalizations.t('Login')),
            toolbarHeight: 56,
            rightWidgets: [_buildRightWidget(context)],
          );

          return Scaffold(
              appBar: appBar,
              body: KeyboardDismissOnTap(
                  dismissOnCapturedTaps: false,
                  child: Stack(children: <Widget>[
                    Opacity(
                      opacity: 1,
                      child: backgroundWidget,
                    ),
                    workspace
                  ])));
        });
  }
}
