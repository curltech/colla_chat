import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:sprintf/sprintf.dart';

import 'package:video_player/video_player.dart';

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

  void onAspectRatioChanged() {
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

  Future<void> onPlayerValueChanged() async {
    final playerValue = widget.controller.value;
    bool isInitializing = !playerValue!.isInitialized && !playerValue.hasError;

    if (!playing.value && playerValue.isPlaying && panelVisibility.value) {
      // if paused -> playing, auto hide panel
      showPanel();
    }

    duration.value = playerValue.duration;
    playing.value = playerValue.isPlaying;
    displayPosition.value = playerValue.position.inMilliseconds;
    volumeValue.value = playerValue.volume;
    buffering.value = playerValue.isBuffering || isInitializing;

    hasClosedCaptionFile.value = widget.controller.closedCaptionFile != null;
    currentCaption.value = playerValue.caption.text;

    if (!isInitializing && aspectRatio.value != playerValue.aspectRatio) {
      aspectRatio.value = playerValue.aspectRatio;
      onAspectRatioChanged();
    }

    if (playerValue.isInitialized &&
        playerValue.duration.inMilliseconds > 0 &&
        playerValue.position.compareTo(playerValue.duration) >= 0) {
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
            if (isPlayEnded && widget.onPlayEnded != null)
              widget.onPlayEnded!();
          });
        }
      }
    } else {
      isPlayEnded = false;
    }
  }

  double volumeBeforeMute = 1.0;

  void toggleVolumeMute() {
    if (volumeValue.value > 0) {
      volumeBeforeMute = math.max(volumeValue.value, 0.3);
      widget.controller.setVolume(0);
    } else {
      widget.controller.setVolume(volumeBeforeMute);
    }
  }

  void restoreOrientation() {
    if (isDesktop) return; //only for mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void doClickFullScreenButton(BuildContext context) {
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
        restoreOrientation(); // when exit fullscreen, unlock screen orientation settings
        isFullscreenVisible = false;
      });
    } else {
      Navigator.of(context).pop();
    }
    FullScreenWindow.setFullScreen(!widget._isFullscreen);
  }

  double iconSize = 10;
  double textSize = 5;

  void evaluateTextIconSize() async {
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
    widget.controller.addListener(onPlayerValueChanged);
    evaluateTextIconSize();
    onPlayerValueChanged();
  }

  @override
  void didUpdateWidget(PlatformMediaControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onPlayerValueChanged);
      widget.controller.addListener(onPlayerValueChanged);
      onPlayerValueChanged();
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
    widget.controller.removeListener(onPlayerValueChanged);
    panelAnimController.dispose();
    volumeAnimController.dispose();
    if (isFullscreenVisible) Navigator.of(context).pop();
    super.dispose();
  }

  String duration2TimeStr(Duration duration) {
    var value = widget.controller.value;
    if (value!.duration.inHours > 0) {
      return sprintf("%02d:%02d:%02d",
          [duration.inHours, duration.inMinutes % 60, duration.inSeconds % 60]);
    }
    return sprintf(
        "%02d:%02d", [duration.inMinutes % 60, duration.inSeconds % 60]);
  }

  Timer? _hidePanelTimer;

  void showPanel() {
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

  void togglePanel() {
    if (_hidePanelTimer != null) {
      _hidePanelTimer?.cancel();
      panelVisibility.value = false;
      panelAnimController.reverse();
      _hidePanelTimer = null;
    } else {
      showPanel();
    }
  }

  Future<void> togglePlayPause() async {
    var value = await widget.controller.value;
    if (!value!.isInitialized) return;
    if (value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void incrementalSeek(int ms) async {
    showPanel();
    int dst = displayPosition.value + ms;
    var value = await widget.controller.value;
    if (dst < 0) {
      dst = 0;
    } else if (dst >= value!.duration.inMilliseconds) {
      return;
    }

    displayPosition.value = dst;
    await widget.controller.seek(Duration(milliseconds: displayPosition.value));
  }

  Widget createPlayPauseButton(bool isCircle, double size) {
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
                togglePlayPause();
              } else {
                if (isPanelShown()) {
                  togglePlayPause();
                  showPanel();
                } else {
                  togglePanel();
                }
              }
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget durationText = ValueListenableBuilder<Duration>(
      valueListenable: duration,
      builder: (context, value, child) {
        return Text(duration2TimeStr(value),
            style: TextStyle(fontSize: textSize, color: Colors.white));
      },
    );

    Widget positionText = ValueListenableBuilder<int>(
      valueListenable: displayPosition,
      builder: (context, value, child) {
        var duration = Duration(milliseconds: value);
        return Text(duration2TimeStr(duration),
            style: TextStyle(fontSize: textSize, color: Colors.white));
      },
    );

    Widget seekBar = ValueListenableBuilder<int>(
      valueListenable: displayPosition,
      builder: (context, value, child) {
        return Slider.adaptive(
          value:
              displayPosition.value < 0 ? 0 : displayPosition.value.toDouble(),
          min: 0,
          max: duration.value.inMilliseconds.toDouble(),
          onChanged: (double value) {
            showPanel();
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

    Widget fullscreenButton = IconButton(
      color: Colors.white,
      iconSize: iconSize,
      icon:
          Icon(widget._isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
      onPressed: () => doClickFullScreenButton(context),
    );

    Widget closedCaptionButton = ValueListenableBuilder(
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
                  showPanel();
                },
              );
            });
      },
    );

    Widget volumePanel = MouseRegion(
      onEnter: (_) {
        volumeAnimController.forward();
        isMouseInVolumeBar = true;
      },
      onExit: (_) {
        if (!isDraggingVolumeBar) volumeAnimController.reverse();
        isMouseInVolumeBar = false;
        showPanel();
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
                      showPanel(); // keep panel visible during dragging volume bar
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
                onPressed: () => toggleVolumeMute(),
              );
            },
          ),
        ]),
      ]),
    );

    Widget? bottomPrevButton = (isDesktop && widget.onPrevClicked != null)
        ? IconButton(
            iconSize: iconSize,
            color: Colors.white,
            icon: const Icon(Icons.skip_previous),
            onPressed: widget.onPrevClicked,
          )
        : null;

    Widget? bottomNextButton = (isDesktop && widget.onNextClicked != null)
        ? IconButton(
            iconSize: iconSize,
            color: Colors.white,
            icon: const Icon(Icons.skip_next),
            onPressed: widget.onNextClicked,
          )
        : null;

    Widget bottomPanel = Column(children: [
      Row(
        children: [
          if (isDesktop) createPlayPauseButton(false, iconSize),
          if (isDesktop && widget.onPrevClicked != null) bottomPrevButton!,
          if (isDesktop && widget.onNextClicked != null) bottomNextButton!,
          positionText,
          Text(" / ",
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

    int lastTapDownTime = 0;
    Widget gestureWidget = GestureDetector(
      onTapUp: (details) {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastTapDownTime > 300) {
          if (isMouseMode) {
            togglePlayPause();
          } else {
            togglePanel();
          }
        } else {
          var width = context.size!.width;
          if (details.localPosition.dx < width / 2) {
            incrementalSeek(-5000);
          } else {
            incrementalSeek(5000);
          }
          showPanel();
        }
        lastTapDownTime = now;
        focusNode.requestFocus();
      },
    );

    Widget bufferingWidget = ValueListenableBuilder<bool>(
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
            return Container();
          }
        });

    Widget panelWidget = Stack(
      alignment: Alignment.center,
      children: [
        if (!isDesktop) Container(color: Colors.black38),
        // translucent black background for panel (only mobile)
        gestureWidget,
        Positioned(left: 0, bottom: 0, right: 0, child: bottomPanel),
        if (!isDesktop)
          Center(child: createPlayPauseButton(true, iconSize * 2.5)),
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
    var value = widget.controller.value;
    panelWidget = Focus(
      autofocus: true,
      focusNode: focusNode,
      child: panelWidget,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.keyF) {
          if (widget.showFullscreenButton) {
            if (event is KeyUpEvent) {
              doClickFullScreenButton(context);
            }
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (widget._isFullscreen) {
            if (event is KeyUpEvent) {
              doClickFullScreenButton(context);
            }
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.space) {
          if (value!.isInitialized) {
            if (event is KeyUpEvent) {
              showPanel();
              togglePlayPause();
            }
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (value!.isInitialized) {
            if (event is! KeyUpEvent) incrementalSeek(-5000);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (value!.isInitialized) {
            if (event is! KeyUpEvent) incrementalSeek(5000);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          if (isDesktop) {
            if (event is KeyUpEvent) {
              toggleVolumeMute();
              showPanel();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );

    panelWidget = ValueListenableBuilder<bool>(
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
              showPanel();
            }
          },
          onEnter: (_) => isMouseMode = true,
          onExit: (_) => isMouseMode = false,
        );
      }),
      child: panelWidget,
    );

    Widget closedCaptionWidget = ValueListenableBuilder<bool>(
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
                    child: Text(value,
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

    Widget videoWidget = ValueListenableBuilder(
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
