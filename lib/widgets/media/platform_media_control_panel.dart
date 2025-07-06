import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:sprintf/sprintf.dart';

SliderThemeData buildSliderTheme(BuildContext context) {
  return SliderTheme.of(context).copyWith(
      trackShape: null,
      //轨道的形状
      trackHeight: 2,
      //trackHeight：滑轨的高度

      activeTrackColor: myself.primary,
      //已滑过轨道的颜色
      inactiveTrackColor: Colors.grey,
      //未滑过轨道的颜色

      //thumbColor: Colors.red,
      //滑块中心的颜色（小圆头的颜色）
      //overlayColor: Colors.greenAccent,
      //滑块边缘的颜色

      thumbShape: const RoundSliderThumbShape(
        //可继承SliderComponentShape自定义形状
        disabledThumbRadius: 6, //禁用时滑块大小
        enabledThumbRadius: 6, //滑块大小
      ),
      overlayShape: const RoundSliderOverlayShape(
        //可继承SliderComponentShape自定义形状
        overlayRadius: 10, //滑块外圈大小
      ));
}

Widget buildSlider(
  BuildContext context, {
  required double value,
  required void Function(double)? onChanged,
  double min = 0.0,
  double max = 1.0,
  int? divisions,
  void Function(double)? onChangeStart,
  void Function(double)? onChangeEnd,
}) {
  return SliderTheme(
    data: buildSliderTheme(context),
    child: Slider(
      min: min,
      max: max,
      value: value,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    ),
  );
}

class PlatformMediaControlPanel extends StatefulWidget {
  final AbstractAudioPlayerController controller;
  final bool showFullscreenButton; // not shown in web
  final bool showClosedCaptionButton;
  final bool showVolumeButton; // only show in desktop
  final VoidCallback? onPrevClicked;
  final VoidCallback? onNextClicked;
  final VoidCallback?
      onPlayEnded; // won't be called if controller set lopping = true
  late bool _isFullscreen;
  ValueNotifier<bool>? _showClosedCaptions;

  PlatformMediaControlPanel(
    this.controller, {
    super.key,
    this.showFullscreenButton = true,
    this.showClosedCaptionButton = true,
    this.showVolumeButton = true,
    this.onPrevClicked,
    this.onNextClicked,
    this.onPlayEnded,
  }) : _isFullscreen = false;

  static PlatformMediaControlPanel _fullscreen(
    AbstractAudioPlayerController controller, {
    Key? key,
    required ValueNotifier<bool>? showClosedCaptions,
    required bool showVolumeButton,
    VoidCallback? onPrevClicked,
    VoidCallback? onNextClicked,
    //this.onPlayEnded, // don't pass to fullscreen widget
  }) {
    var c = PlatformMediaControlPanel(
      controller,
      key: key,
      showVolumeButton: showVolumeButton,
      onPrevClicked: onPrevClicked,
      onNextClicked: onNextClicked,
    );
    c._isFullscreen = true;
    c._showClosedCaptions = showClosedCaptions;
    return c;
  }

  @override
  State<PlatformMediaControlPanel> createState() =>
      _PlatformMediaControlPanelState();
}

class _PlatformMediaControlPanelState extends State<PlatformMediaControlPanel>
    with TickerProviderStateMixin {
  final bool isDesktop = kIsWeb || Platform.isWindows;
  final focusNode = FocusNode();

  late final AnimationController panelAnimController = AnimationController(
      duration: const Duration(milliseconds: 300), vsync: this);
  late final panelAnimation =
      panelAnimController.drive(Tween<double>(begin: 0.0, end: 1.0));
  late final AnimationController volumeAnimController = AnimationController(
      duration: const Duration(milliseconds: 100), vsync: this);
  late final volumeAnimation =
      volumeAnimController.drive(Tween<double>(begin: 0.0, end: 1.0));

  final displayPosition = ValueNotifier<int>(
      0); // position to display for user, when user dragging seek bar, this value changed by user dragging, not changed by player's position

  final aspectRatio = ValueNotifier<double>(1);
  final duration = ValueNotifier<Duration>(Duration.zero);
  final playing = ValueNotifier<bool>(false);
  final buffering = ValueNotifier<bool>(false);
  final volumeValue = ValueNotifier<double>(1.0);
  final controllerValue = ValueNotifier<int>(
      0); // used to notify fullscreen widget that controller changed

  final hasClosedCaptionFile = ValueNotifier<bool>(false);
  late final ValueNotifier<bool> showClosedCaptions;
  final currentCaption = ValueNotifier<String>("");

  bool isMouseMode = false;
  final panelVisibility = ValueNotifier<bool>(
      false); // is panel visible, used to show/hide mouse cursor, and enable/disable click on buttons on panel

  bool isDraggingVolumeBar = false;
  bool isMouseInVolumeBar = false;

  bool isPlayEnded = false;
  bool isFullscreenVisible = false;

  void _onAspectRatioChanged() {
    if (!isDesktop && widget._isFullscreen) {
      // if in fullscreen mode, auto force set orientation for android / iOS
      if (aspectRatio.value > 1.05) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else if (aspectRatio.value < 0.95) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    }
  }

  Future<void> _onPlayerValueChanged() async {
    final mediaPlayerState = widget.controller.mediaPlayerState;
    bool isInitializing =
        mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.init;
    bool isInitialized =
        mediaPlayerState.mediaPlayerStatus != MediaPlayerStatus.none &&
            mediaPlayerState.mediaPlayerStatus != MediaPlayerStatus.init;

    if (!playing.value &&
        mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.playing &&
        panelVisibility.value) {
      // if paused -> playing, auto hide panel
      _showPanel();
    }

    duration.value = mediaPlayerState.duration;
    playing.value =
        mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.playing;
    displayPosition.value = mediaPlayerState.position.inMilliseconds;
    volumeValue.value = mediaPlayerState.volume;
    buffering.value =
        mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.buffering;

    hasClosedCaptionFile.value = widget.controller.closedCaptionFile != null;
    currentCaption.value = mediaPlayerState.caption ?? '';

    if (!isInitializing && aspectRatio.value != mediaPlayerState.aspectRatio) {
      aspectRatio.value = mediaPlayerState.aspectRatio!;
      _onAspectRatioChanged();
    }

    if (isInitialized &&
        mediaPlayerState.duration.inMilliseconds > 0 &&
        mediaPlayerState.position.compareTo(mediaPlayerState.duration) >= 0) {
      if (!isPlayEnded) {
        isPlayEnded = true;
        playing.value = false;
        if (widget.onPlayEnded != null) {
          // NOTE: if user drag seekbar to end, so controller.seekTo(end) called,
          // it make official [video_player] call platform.seekTo(end).then(() => getPosition());
          // if we call widget.onPlayEnded() immediately after call seekTo(end),
          // user called may call controller.dispose() in widget.onPlayEnded() immediated,
          // which make [video_player] throw Error when it wait seekTo() finished and then call getPosition()...
          Future.delayed(const Duration(milliseconds: 300)).then((value) {
            if (isPlayEnded && widget.onPlayEnded != null) {
              widget.onPlayEnded!();
            }
          });
        }
      }
    } else {
      isPlayEnded = false;
    }
  }

  double volumeBeforeMute = 1.0;

  void _toggleVolumeMute() {
    if (volumeValue.value > 0) {
      volumeBeforeMute = math.max(volumeValue.value, 0.3);
      widget.controller.setVolume(0);
    } else {
      widget.controller.setVolume(volumeBeforeMute);
    }
  }

  void _restoreOrientation() {
    if (isDesktop) return; //only for mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _doClickFullScreenButton(BuildContext context) {
    if (!widget._isFullscreen) {
      isFullscreenVisible = true;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          // NOTE: when setState() called in didUpdateWidget() in non-fullscreen widget, this will be called here... why ? but it sounds good here!
          return Material(
            child: ValueListenableBuilder(
              valueListenable: controllerValue,
              builder: ((context, value, child) {
                return PlatformMediaControlPanel._fullscreen(
                  widget.controller,
                  key: widget.key,
                  showClosedCaptions: showClosedCaptions,
                  showVolumeButton: widget.showVolumeButton,
                  onPrevClicked: widget.onPrevClicked,
                  onNextClicked: widget.onNextClicked,
                );
              }),
            ),
          );
        }),
      ).then((value) {
        _restoreOrientation(); // when exit fullscreen, unlock screen orientation settings
        isFullscreenVisible = false;
      });
    } else {
      Navigator.of(context).pop();
    }
    FullScreenWindow.setFullScreen(!widget._isFullscreen);
  }

  double iconSize = 10;
  double textSize = 5;

  void _evaluateTextIconSize() async {
    var size = await FullScreenWindow.getScreenSize(context);
    double min = math.min(size.width, size.height);
    if (kIsWeb || Platform.isWindows) {
      iconSize = min / 30;
    } else {
      // android / iOS
      iconSize = min / 15;
    }

    textSize = iconSize * 0.55;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    showClosedCaptions =
        widget._showClosedCaptions ?? ValueNotifier<bool>(true);
    widget.controller.addListener(_onPlayerValueChanged);
    _evaluateTextIconSize();
    _onPlayerValueChanged();
  }

  @override
  void didUpdateWidget(PlatformMediaControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onPlayerValueChanged);
      widget.controller.addListener(_onPlayerValueChanged);
      _onPlayerValueChanged();
      setState(() {});
      Future.delayed(Duration.zero).then((value) {
        controllerValue
            .value++; //notify fullscreen widget to rebuild, async delay is needed
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    widget.controller.removeListener(_onPlayerValueChanged);
    panelAnimController.dispose();
    volumeAnimController.dispose();
    if (isFullscreenVisible) Navigator.of(context).pop();
    super.dispose();
  }

  String _duration2TimeStr(Duration duration) {
    var value = widget.controller.mediaPlayerState;
    if (value.duration.inHours > 0) {
      return sprintf("%02d:%02d:%02d",
          [duration.inHours, duration.inMinutes % 60, duration.inSeconds % 60]);
    }
    return sprintf(
        "%02d:%02d", [duration.inMinutes % 60, duration.inSeconds % 60]);
  }

  Timer? _hidePanelTimer;

  void _showPanel() {
    panelVisibility.value = true;
    panelAnimController.forward();
    _hidePanelTimer?.cancel();
    _hidePanelTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (isMouseInVolumeBar || isDraggingVolumeBar) return;
      if (!playing.value) return; //don't auto hide when paused
      panelVisibility.value = false;
      panelAnimController.reverse();
      _hidePanelTimer = null;
    });
  }

  bool isPanelShown() => panelAnimController.value > 0;

  void _togglePanel() {
    if (_hidePanelTimer != null) {
      _hidePanelTimer?.cancel();
      panelVisibility.value = false;
      panelAnimController.reverse();
      _hidePanelTimer = null;
    } else {
      _showPanel();
    }
  }

  void _togglePlayPause() {
    var mediaPlayerState = widget.controller.mediaPlayerState;
    if (!mediaPlayerState.isInitialized) {
      return;
    }
    if (mediaPlayerState.mediaPlayerStatus == MediaPlayerStatus.playing) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void _incrementalSeek(int ms) {
    _showPanel();
    int dst = displayPosition.value + ms;
    var value = widget.controller.mediaPlayerState;
    if (dst < 0) {
      dst = 0;
    } else if (dst >= value.duration.inMilliseconds) {
      return;
    }

    displayPosition.value = dst;
    widget.controller.seek(Duration(milliseconds: displayPosition.value));
  }

  Widget _buildPlayPauseButton(bool isCircle, double size) {
    return ValueListenableBuilder<bool>(
        valueListenable: playing,
        builder: (context, value, child) {
          return IconButton(
            iconSize: size,
            icon: Icon(
                isCircle
                    ? (value ? Icons.pause_circle : Icons.play_circle)
                    : (value ? Icons.pause : Icons.play_arrow),
                color: Colors.white),
            onPressed: () {
              if (isMouseMode) {
                _togglePlayPause();
              } else {
                if (isPanelShown()) {
                  _togglePlayPause();
                  _showPanel();
                } else {
                  _togglePanel();
                }
              }
            },
          );
        });
  }

  Widget _buildMouseRegion(Widget panelWidget) {
    return ValueListenableBuilder<bool>(
      valueListenable: panelVisibility,
      builder: ((context, value, child) {
        return MouseRegion(
          // TODO: this not work...
          // issue: https://github.com/flutter/flutter/issues/76622
          // because when set cursor to [none] after mouse freeze 2 seconds,
          // mouse must move 1 pixel to make MouseRegion apply the cursor settings...
          cursor: panelVisibility.value
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          child: child,
          onHover: (_) {
            // NOTE: touch on android will cause onHover... why ???
            if (isMouseMode) {
              _showPanel();
            }
          },
          onEnter: (_) => isMouseMode = true,
          onExit: (_) => isMouseMode = false,
        );
      }),
      child: panelWidget,
    );
  }

  Widget _buildFocusNode(
    BuildContext context,
    Widget panelWidget,
  ) {
    var value = widget.controller.mediaPlayerState;
    return Focus(
      autofocus: true,
      focusNode: focusNode,
      child: panelWidget,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.keyF) {
          if (widget.showFullscreenButton) {
            if (event is KeyUpEvent) {
              _doClickFullScreenButton(context);
            }
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (widget._isFullscreen) {
            if (event is KeyUpEvent) {
              _doClickFullScreenButton(context);
            }
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.space) {
          if (value.isInitialized) {
            if (event is KeyUpEvent) {
              _showPanel();
              _togglePlayPause();
            }
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (value.isInitialized) {
            if (event is! KeyUpEvent) _incrementalSeek(-5000);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (value.isInitialized) {
            if (event is! KeyUpEvent) _incrementalSeek(5000);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          if (isDesktop) {
            if (event is KeyUpEvent) {
              _toggleVolumeMute();
              _showPanel();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  Widget _buildMoveButton(Widget gestureWidget, Widget bottomPanel) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!isDesktop) Container(color: Colors.black38),
        // translucent black background for panel (only mobile)
        gestureWidget,
        Positioned(left: 0, bottom: 0, right: 0, child: bottomPanel),
        if (!isDesktop)
          Center(child: _buildPlayPauseButton(true, iconSize * 2.5)),
        if (!isDesktop && widget.onPrevClicked != null)
          Align(
              alignment: const FractionalOffset(0.15, 0.5),
              child: IconButton(
                onPressed: widget.onPrevClicked,
                icon: const Icon(Icons.skip_previous),
                iconSize: iconSize * 1.5,
                color: Colors.white,
              )),
        if (!isDesktop && widget.onNextClicked != null)
          Align(
              alignment: const FractionalOffset(0.85, 0.5),
              child: IconButton(
                onPressed: widget.onNextClicked,
                icon: const Icon(Icons.skip_next),
                iconSize: iconSize * 1.5,
                color: Colors.white,
              )),
      ],
    );
  }

  Widget _buildBufferingWidget() {
    return ValueListenableBuilder<bool>(
        valueListenable: buffering,
        builder: (context, value, child) {
          if (value) {
            return Center(
              child: SizedBox(
                width: iconSize * 3,
                height: iconSize * 3,
                child: const CircularProgressIndicator(),
              ),
            );
          } else {
            return nilBox;
          }
        });
  }

  Widget _buildGestureDetector(BuildContext context) {
    int lastTapDownTime = 0;
    return GestureDetector(
      onTapUp: (details) {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastTapDownTime > 300) {
          if (isMouseMode) {
            _togglePlayPause();
          } else {
            _togglePanel();
          }
        } else {
          var width = context.size!.width;
          if (details.localPosition.dx < width / 2) {
            _incrementalSeek(-5000);
          } else {
            _incrementalSeek(5000);
          }
          _showPanel();
        }
        lastTapDownTime = now;
        focusNode.requestFocus();
      },
    );
  }

  Widget _buildBottomPanel(
      Widget? bottomPrevButton,
      Widget? bottomNextButton,
      Widget positionText,
      Widget durationText,
      Widget volumePanel,
      Widget closedCaptionButton,
      Widget fullscreenButton,
      Widget seekBar) {
    Widget bottomPanel = Column(children: [
      Row(
        children: [
          if (isDesktop) _buildPlayPauseButton(false, iconSize),
          if (isDesktop && widget.onPrevClicked != null) bottomPrevButton!,
          if (isDesktop && widget.onNextClicked != null) bottomNextButton!,
          positionText,
          AutoSizeText(" / ",
              style: TextStyle(fontSize: textSize, color: Colors.white)),
          durationText,
          const Spacer(),
          if (isDesktop && widget.showVolumeButton) volumePanel,
          if (widget.showClosedCaptionButton) closedCaptionButton,
          if (widget.showFullscreenButton && !kIsWeb) fullscreenButton,
          //TODO: fullscreen makes video black after exit fullscreen in web environment, so remove it
        ],
      ),
      seekBar,
    ]);
    bottomPanel = Container(
      padding: EdgeInsets.all(iconSize / 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            //colors: !isDesktop ? <Color>[Colors.transparent, Colors.transparent] : <Color>[Colors.transparent, Colors.black87]),
            colors: <Color>[
              Colors.transparent,
              isDesktop ? Colors.black87 : Colors.transparent
            ]),
      ),
      child: bottomPanel,
    );

    return bottomPanel;
  }

  Widget? _buildBottomNextButton() {
    return (isDesktop && widget.onNextClicked != null)
        ? IconButton(
            iconSize: iconSize,
            color: Colors.white,
            icon: const Icon(Icons.skip_next),
            onPressed: widget.onNextClicked,
          )
        : null;
  }

  Widget? _buildBottomPrevButton() {
    return (isDesktop && widget.onPrevClicked != null)
        ? IconButton(
            iconSize: iconSize,
            color: Colors.white,
            icon: const Icon(Icons.skip_previous),
            onPressed: widget.onPrevClicked,
          )
        : null;
  }

  Widget _buildVolumePanel() {
    return MouseRegion(
      onEnter: (_) {
        volumeAnimController.forward();
        isMouseInVolumeBar = true;
      },
      onExit: (_) {
        if (!isDraggingVolumeBar) volumeAnimController.reverse();
        isMouseInVolumeBar = false;
        _showPanel();
      },
      child: Stack(children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: volumeAnimation,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(color: Colors.transparent),
                  borderRadius: const BorderRadius.all(Radius.circular(100))),
            ),
          ),
        ),
        Row(children: [
          SizeTransition(
            axis: Axis.horizontal,
            sizeFactor: volumeAnimation,
            child: ValueListenableBuilder<double>(
              valueListenable: volumeValue,
              builder: (context, value, child) {
                return Slider(
                    min: 0,
                    max: 100,
                    value: value * 100,
                    divisions: 100,
                    onChangeStart: (_) => isDraggingVolumeBar = true,
                    onChangeEnd: (_) {
                      isDraggingVolumeBar = false;
                      if (!isMouseInVolumeBar) volumeAnimController.reverse();
                    },
                    onChanged: (value) {
                      widget.controller.setVolume(value / 100);
                      _showPanel(); // keep panel visible during dragging volume bar
                    });
              },
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: volumeValue,
            builder: (context, value, child) {
              bool isMute = value <= 0;
              return IconButton(
                color: isMute ? Colors.red : Colors.white,
                iconSize: iconSize,
                icon: Icon(isMute ? Icons.volume_off : Icons.volume_up),
                onPressed: () => _toggleVolumeMute(),
              );
            },
          ),
        ]),
      ]),
    );
  }

  Widget _buildClosedCaptionButton() {
    return ValueListenableBuilder(
      valueListenable: hasClosedCaptionFile,
      builder: (context, value, child) {
        if (!value) return const SizedBox.shrink();
        return ValueListenableBuilder(
            valueListenable: showClosedCaptions,
            builder: (context, value, child) {
              return IconButton(
                color: Colors.white,
                iconSize: iconSize,
                icon: Icon(
                    value ? Icons.subtitles : Icons.subtitles_off_outlined),
                onPressed: () {
                  showClosedCaptions.value = !showClosedCaptions.value;
                  _showPanel();
                },
              );
            });
      },
    );
  }

  Widget _buildFullscreenButton(BuildContext context) {
    return IconButton(
      color: Colors.white,
      iconSize: iconSize,
      icon:
          Icon(widget._isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
      onPressed: () => _doClickFullScreenButton(context),
    );
  }

  Widget _buildSeekBar() {
    Widget seekBar = ValueListenableBuilder<int>(
      valueListenable: displayPosition,
      builder: (context, value, child) {
        return Slider.adaptive(
          value:
              displayPosition.value < 0 ? 0 : displayPosition.value.toDouble(),
          min: 0,
          max: duration.value.inMilliseconds.toDouble(),
          onChanged: (double value) {
            _showPanel();
            displayPosition.value = value.toInt();
            widget.controller.seek(Duration(milliseconds: value.toInt()));
          },
        );
      },
    );
    seekBar = SliderTheme(
      data: const SliderThemeData(
          thumbColor: Colors.white,
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white70,
          trackHeight: 1,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: SizedBox(height: iconSize * 0.7, child: seekBar),
    );

    return seekBar;
  }

  Widget _buildPositionText() {
    return ValueListenableBuilder<int>(
      valueListenable: displayPosition,
      builder: (context, value, child) {
        var duration = Duration(milliseconds: value);
        return AutoSizeText(_duration2TimeStr(duration),
            style: TextStyle(fontSize: textSize, color: Colors.white));
      },
    );
  }

  Widget _buildDurationText() {
    return ValueListenableBuilder<Duration>(
      valueListenable: duration,
      builder: (context, value, child) {
        return AutoSizeText(_duration2TimeStr(value),
            style: TextStyle(fontSize: textSize, color: Colors.white));
      },
    );
  }

  Widget _buildClosedCaption() {
    return ValueListenableBuilder<bool>(
        valueListenable: showClosedCaptions,
        builder: (context, value, child) {
          if (!value) return const SizedBox.shrink();
          return ValueListenableBuilder<String>(
            valueListenable: currentCaption,
            builder: (context, value, child) {
              return LayoutBuilder(builder: (context, constraints) {
                double textSize = constraints.maxWidth * 0.028;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.all(textSize / 2),
                    child: AutoSizeText(value,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: textSize,
                            color: Colors.white,
                            backgroundColor: Colors.black54)),
                  ),
                );
              });
            },
          );
        });
  }

  Widget _buildMediaPlayer(Widget closedCaptionWidget) {
    return ValueListenableBuilder(
      valueListenable: aspectRatio,
      builder: (context, value, child) {
        return Center(
          child: AspectRatio(
            aspectRatio: value,
            child: Stack(children: [
              widget.controller.buildMediaPlayer(key: UniqueKey()),
              closedCaptionWidget,
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget durationText = _buildDurationText();

    Widget positionText = _buildPositionText();

    Widget seekBar = _buildSeekBar();

    Widget fullscreenButton = _buildFullscreenButton(context);

    Widget closedCaptionButton = _buildClosedCaptionButton();

    Widget volumePanel = _buildVolumePanel();

    Widget? bottomPrevButton = _buildBottomPrevButton();

    Widget? bottomNextButton = _buildBottomNextButton();

    Widget bottomPanel = _buildBottomPanel(
        bottomPrevButton,
        bottomNextButton,
        positionText,
        durationText,
        volumePanel,
        closedCaptionButton,
        fullscreenButton,
        seekBar);

    Widget gestureWidget = _buildGestureDetector(context);

    Widget bufferingWidget = _buildBufferingWidget();

    Widget panelWidget = _buildMoveButton(gestureWidget, bottomPanel);

    panelWidget = FadeTransition(opacity: panelAnimation, child: panelWidget);

    panelWidget = ValueListenableBuilder(
      valueListenable: panelVisibility,
      builder: (context, value, child) =>
          IgnorePointer(ignoring: !value, child: child),
      child: panelWidget,
    );

    panelWidget = Stack(children: [
      gestureWidget,
      panelWidget,
    ]);

    panelWidget = _buildFocusNode(context, panelWidget);

    panelWidget = _buildMouseRegion(panelWidget);

    Widget closedCaptionWidget = _buildClosedCaption();

    Widget videoWidget = _buildMediaPlayer(closedCaptionWidget);

    Widget allWidgets = Stack(
      children: [
        Container(color: Colors.black),
        // video_player open file need time, so put a black bg here
        videoWidget,
        bufferingWidget,
        panelWidget,
      ],
    );

    return allWidgets;
  }
}
