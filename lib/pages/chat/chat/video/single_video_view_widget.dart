import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

import '../../../../transport/webrtc/peer_video_render.dart';
import '../controller/peer_connections_controller.dart';

final List<ActionData> actionData = [
  ActionData(label: 'Camera switch', icon: const Icon(Icons.cameraswitch)),
  ActionData(label: 'Microphone switch', icon: const Icon(Icons.mic_rounded)),
  ActionData(label: 'Speaker switch', icon: const Icon(Icons.speaker_phone)),
  ActionData(label: 'Decrease volume', icon: const Icon(Icons.volume_down)),
  ActionData(label: 'Increase volume', icon: const Icon(Icons.volume_up)),
];

///单个视频窗口，长按出现更大的窗口，带有操作按钮
class SingleVideoViewWidget extends StatefulWidget {
  final PeerVideoRender render;
  final double? height;
  final double? width;
  final Color? color;

  const SingleVideoViewWidget({
    Key? key,
    required this.render,
    this.height,
    this.width,
    this.color,
  }) : super(key: key);

  @override
  State createState() => _SingleVideoViewWidgetState();
}

class _SingleVideoViewWidgetState extends State<SingleVideoViewWidget> {
  late OverlayEntry _popupDialog;

  @override
  initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  OverlayEntry _createPopupDialog() {
    return OverlayEntry(
      builder: (context) =>
          AnimatedContain(
            child: _createPopupContent(),
          ),
    );
  }

  Widget _createPopupContent() {
    var height = MediaQuery
        .of(context)
        .size
        .height - 56;
    var width = MediaQuery
        .of(context)
        .size
        .width;
    Widget videoView = widget.render
        .createVideoView(height: height, width: width, color: widget.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          children: [
            _buildAppBar(),
            Stack(children: [videoView, _buildActionCard(context)]),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    var title = widget.render.name ?? '';
    var ownerTag = widget.render.ownerTag ?? '';
    title = '$title($ownerTag)';
    return AppBarWidget.build(context, title: Text(title), rightWidgets: [
      InkWell(
          onTap: () {
            _popupDialog?.remove();
          },
          child: const Icon(Icons.close))
    ]);
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (index) {
      case 0:
        await widget.render.switchCamera();
        break;
      case 1:
        await widget.render.switchSpeaker(true);
        break;
      case 2:
        widget.render.setMute(true);
        break;
      case 3:
        await widget.render.setVolume(0);
        break;
      case 4:
        await widget.render.setVolume(0);
        break;
      default:
        break;
    }
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 80;
    Widget actionCard = Card(
      elevation: 0,
      child: Center(
          child: Container(
            height: height,
            margin: const EdgeInsets.all(0.0),
            padding: const EdgeInsets.only(bottom: 0.0),
            child: DataActionCard(
              actions: actionData,
              height: height,
              onPressed: _onAction, crossAxisCount: 4,
            ),
          )),
    );
    return actionCard;
  }

  ///单个视频窗口
  Widget _buildSingleVideoView(BuildContext context) {
    Widget videoView = widget.render.createVideoView(
        height: widget.height, width: widget.width, color: widget.color);
    Widget singleVideoView = Builder(
      // use Builder here in order to show the snakbar
      builder: (context) =>
          GestureDetector(
            // keep the OverlayEntry instance, and insert it into Overlay
            onLongPress: () {
              _popupDialog = _createPopupDialog();
              Overlay.of(context)?.insert(_popupDialog);
            },
            // remove the OverlayEntry from Overlay, so it would be hidden
            //onLongPressEnd: (details) => _popupDialog?.remove(),

            onTap: () {
              DialogUtil.info(context, content: AppLocalizations.t(''));
            },
            child: videoView,
          ),
    );

    return singleVideoView;
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleVideoView(context);
  }

  @override
  void dispose() {
    peerConnectionsController.removeListener(_update);
    super.dispose();
  }
}

// This a widget to implement the image scale animation, and background grey out effect.
class AnimatedContain extends StatefulWidget {
  const AnimatedContain({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<StatefulWidget> createState() => AnimatedContainState();
}

class AnimatedContainState extends State<AnimatedContain>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacityAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    scaleAnimation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutExpo);
    opacityAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutExpo));

    controller.addListener(() => setState(() {}));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(opacityAnimation.value),
      child: Center(
        child: FadeTransition(
          opacity: scaleAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
