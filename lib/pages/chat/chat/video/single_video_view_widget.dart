import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/transport/webrtc/peer_connections_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';

final List<ActionData> videoActionData = [
  ActionData(
      label: 'Camera switch',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.cameraswitch)),
  ActionData(
      label: 'Microphone switch',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.mic_rounded)),
  ActionData(
      label: 'Speaker switch',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.speaker_phone)),
  ActionData(
      label: 'Volume increase',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.volume_up)),
  ActionData(
      label: 'Volume decrease',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.volume_down)),
  ActionData(
      label: 'Volume mute',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.volume_mute)),
  ActionData(
      label: 'Zoom out',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.zoom_out_map)),
  ActionData(
      label: 'Zoom in',
      actionType: ActionType.inkwell,
      icon: const Icon(Icons.zoom_in_map)),
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
  bool actionVisible = false;
  late OverlayEntry _popupDialog;

  @override
  initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  OverlayEntry _buildPopupDialog() {
    return OverlayEntry(
      builder: (context) => AnimatedContain(
        child: _buildPopupVideoView(),
      ),
    );
  }

  Widget _buildAppBar() {
    return _buildActionCard(context);
  }

  Widget _buildPopupVideoView() {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    Widget videoView = Stack(children: [
      widget.render
          .createVideoView(height: height, width: width, color: widget.color),
      _buildAppBar(),
    ]);

    return videoView;
  }

  Widget _buildActionCard(BuildContext context) {
    return Visibility(
        visible: actionVisible,
        child: Card(
            child: DataActionCard(
                onPressed: (int index, String label, {String? value}) {
                  _onAction(context, index, label, value: value);
                },
                showLabel: false,
                showTooltip: false,
                crossAxisCount: 4,
                actions: videoActionData,
                // height: 120,
                //width: 320,
                size: 20)));
  }

  ///单个视频窗口
  Widget _buildSingleVideoView(
      BuildContext context, double? height, double? width) {
    String name = widget.render.name ?? '';
    Widget actionWidget = _buildActionCard(context);
    Widget videoView = widget.render
        .createVideoView(height: height, width: width, color: widget.color);
    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onTap: () {
          setState(() {
            actionVisible = !actionVisible;
          });
        },
        child: videoView,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Stack(
        children: [
          singleVideoView,
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actionWidget,
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    switch (name) {
      case 'Camera switch':
        await widget.render.switchCamera();
        break;
      case 'Microphone switch':
        await widget.render.switchSpeaker(true);
        break;
      case 'Speaker switch':
        widget.render.setMute(true);
        break;
      case 'Volume increase':
        await widget.render.setVolume(0);
        break;
      case 'Volume decrease':
        await widget.render.setVolume(0);
        break;
      case 'Volume mute':
        await widget.render.setVolume(0);
        break;
      case 'Zoom out':
        _popupDialog = _buildPopupDialog();
        Overlay.of(context)?.insert(_popupDialog);
        break;
      case 'Zoom in':
        _popupDialog.remove();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleVideoView(context, widget.height, widget.width);
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
