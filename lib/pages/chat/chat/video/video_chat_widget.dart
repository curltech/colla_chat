import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/local_video_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/remote_video_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

final List<ActionData> actionData = [
  ActionData(
      label: 'Minimize',
      tooltip: 'Minimize',
      icon: const Icon(Icons.zoom_in_map, color: Colors.white)),
];

///视频通话窗口，分页显示本地视频和远程视频
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  const VideoChatWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoChatWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_chat';

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'VideoChat';
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  ValueNotifier<bool> actionCardVisible =
      ValueNotifier<bool>(false); // position to false;
  Timer? _hidePanelTimer;

  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
  }

  _closeOverlayEntry() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  _minimize(BuildContext context) {
    overlayEntry = OverlayEntry(builder: (context) {
      return Align(
        alignment: Alignment.topRight,
        child: WidgetUtil.buildCircleButton(
            padding: const EdgeInsets.all(15.0),
            backgroundColor: appDataProvider.themeData.colorScheme.primary,
            onPressed: () {
              _closeOverlayEntry();
            },
            child:
                const Icon(size: 32, color: Colors.white, Icons.zoom_out_map)),
      );
    });
    Overlay.of(context)!.insert(overlayEntry!);
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Minimize':
        _minimize(context);
        break;
      default:
        break;
    }
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 80;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: actionData,
        height: height,
        onPressed: _onAction,
        crossAxisCount: 4,
        labelColor: Colors.white,
      ),
    );
  }

  ///控制面板
  Widget _buildControlPanel(BuildContext context) {
    return Column(children: [
      ValueListenableBuilder<bool>(
          valueListenable: actionCardVisible,
          builder: (context, value, child) {
            return Visibility(
              visible: actionCardVisible.value,
              child: _buildActionCard(context),
            );
          }),
      const Spacer(),
    ]);
  }

  Widget _buildVideoChatView(BuildContext context) {
    return Swiper(
      controller: SwiperController(),
      itemCount: 2,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        Widget view = const LocalVideoWidget();
        if (index == 1) {
          view = const RemoteVideoWidget();
        }
        return Center(child: view);
      },
      // pagination: SwiperPagination(
      //     builder: DotSwiperPaginationBuilder(
      //   activeColor: appDataProvider.themeData.colorScheme.primary,
      //   color: Colors.white,
      //   activeSize: 15,)
      // ),
    );
  }

  ///切换显示按钮面板
  void _toggleActionCard() {
    if (_hidePanelTimer != null) {
      _hidePanelTimer?.cancel();
      actionCardVisible.value = false;
      _hidePanelTimer = null;
    } else {
      actionCardVisible.value = true;
      _hidePanelTimer?.cancel();
      _hidePanelTimer = Timer(const Duration(seconds: 15), () {
        if (!mounted) return;
        actionCardVisible.value = false;
        _hidePanelTimer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget gestureDetector = GestureDetector(
      child: _buildVideoChatView(context),
      onDoubleTap: () {
        _toggleActionCard();
        //focusNode.requestFocus();
      },
    );
    return AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: true,
        child: Stack(children: [
          gestureDetector,
          _buildControlPanel(context),
        ]));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
