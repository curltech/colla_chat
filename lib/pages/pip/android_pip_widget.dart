import 'dart:math';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/material.dart';
import 'package:android_pip/actions/pip_action.dart';
import 'package:android_pip/actions/pip_actions_layout.dart';
import 'dart:async';

import 'package:android_pip/android_pip.dart';
import 'package:android_pip/pip_widget.dart';

import 'package:floating/floating.dart';

/// android_pip实现android的背景画中画功能
class BackgroundAndroidPipWidget extends StatefulWidget {
  const BackgroundAndroidPipWidget({super.key});

  @override
  State<BackgroundAndroidPipWidget> createState() =>
      _BackgroundAndroidPipWidgetState();
}

class _BackgroundAndroidPipWidgetState
    extends State<BackgroundAndroidPipWidget> {
  /// Some aspect ratio presets to choose
  List<List<int>> aspectRatios = [
    [1, 1],
    [2, 3],
    [3, 2],
    [16, 9],
    [9, 16],
  ];
  bool pipAvailable = false;
  late List<int> aspectRatio = aspectRatios.first;
  bool autoPipAvailable = false;
  bool autoPipSwitch = false;
  late AndroidPIP pip;

  PipActionsLayout pipActionsLayout = PipActionsLayout.none;

  // Used to represent interaction with PIP actions
  bool isPlaying = true;
  String actionResponse = "";

  @override
  void initState() {
    super.initState();
    // Instance a pip without callbacks to use it only to activate pip mode
    pip = AndroidPIP();
    requestPipAvailability();
  }

  /// Checks if system supports PIP mode
  Future<void> requestPipAvailability() async {
    var isAvailable = await AndroidPIP.isPipAvailable;
    var isAutoPipAvailable = await AndroidPIP.isAutoPipAvailable;
    setState(() {
      pipAvailable = isAvailable;
      autoPipAvailable = isAutoPipAvailable;
    });
  }

  List<DropdownMenuItem<PipActionsLayout>> layoutList() {
    return PipActionsLayout.values
        .map<DropdownMenuItem<PipActionsLayout>>(
          (PipActionsLayout value) => DropdownMenuItem<PipActionsLayout>(
            value: value,
            child: Text(value.name),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Pip widget can build different widgets for each mode
      home: PipWidget(
        // builder is null so child is used when not in pip mode
        onPipMaximised: () {
          logger.i("PIP To APP");
        },
        onPipExited: () {
          logger.i("Exited from PIP");
        },
        onPipEntered: () {
          logger.i("App to PIP");
        },
        // useIndexedStack: false,
        pipLayout: pipActionsLayout,
        onPipAction: (action) {
          logger.i("PIP ACTION TAP: ${action.name}");
          switch (action) {
            case PipAction.play:
              // example: videoPlayerController.play();
              setState(() {
                isPlaying = true;
                actionResponse = "Playing";
              });
              break;
            case PipAction.pause:
              // example: videoPlayerController.pause();
              setState(() {
                isPlaying = false;
                actionResponse = "Paused";
              });
              break;
            case PipAction.live:
              // example: videoPlayerController.forceLive();
              setState(() {
                actionResponse = "Go to live view";
              });
              break;
            case PipAction.next:
              // example: videoPlayerController.next();
              setState(() {
                actionResponse = "Next";
              });
              break;
            case PipAction.previous:
              // example: videoPlayerController.previous();
              setState(() {
                actionResponse = "Previous";
              });
              break;
            default:
              break;
          }
        },
        // pip builder is null so pip child is used when in pip mode
        pipChild: Scaffold(
          appBar: AppBar(
            title: const Text('Pip Mode'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: double.infinity),
              const Text('Pip activated'),
              pipActionsLayout != PipActionsLayout.none
                  ? IconButton(
                      onPressed: () {
                        bool newValue = !isPlaying;
                        pip.setIsPlaying(newValue);
                        setState(() {
                          isPlaying = newValue;
                        });
                      },
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow))
                  : Container(),
              pipActionsLayout != PipActionsLayout.none
                  ? Text(actionResponse)
                  : Container(),
            ],
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pip Plugin example app'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: double.infinity),
              Text('Pip is ${pipAvailable ? '' : 'not '}Available'),
              const Text('Pip is not activated'),
              DropdownButton<List<int>>(
                value: aspectRatio,
                onChanged: (List<int>? newValue) {
                  if (newValue == null) return;
                  if (autoPipSwitch) {
                    pip.setAutoPipMode(
                      aspectRatio: newValue,
                      seamlessResize: true,
                    );
                  }
                  setState(() {
                    aspectRatio = newValue;
                  });
                },
                items: aspectRatios
                    .map<DropdownMenuItem<List<int>>>(
                      (List<int> value) => DropdownMenuItem<List<int>>(
                        value: value,
                        child: Text('${value.first} : ${value.last}'),
                      ),
                    )
                    .toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Auto Enter (Android S): '),
                  Switch(
                    value: autoPipSwitch,
                    onChanged: autoPipAvailable
                        ? (newValue) {
                            setState(() {
                              autoPipSwitch = newValue;
                            });
                            pip.setAutoPipMode(
                              aspectRatio: aspectRatio,
                              autoEnter: autoPipSwitch,
                              seamlessResize: true,
                            );
                          }
                        : null,
                  ),
                ],
              ),
              IconButton(
                onPressed: pipAvailable
                    ? () => pip.enterPipMode(
                          aspectRatio: aspectRatio,
                        )
                    : null,
                icon: const Icon(Icons.picture_in_picture),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(
                  thickness: 1,
                ),
              ),
              const Text("PIP Actions:"),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Current actions layout: "),
                    DropdownButton<PipActionsLayout>(
                      value: pipActionsLayout,
                      onChanged: (PipActionsLayout? newValue) {
                        if (newValue == null) return;
                        pip.setPipActionsLayout(newValue);
                        pip.setIsPlaying(true);
                        setState(() {
                          isPlaying = true;
                          pipActionsLayout = newValue;
                        });
                      },
                      items: layoutList(),
                    ),
                  ],
                ),
              ),
              pipActionsLayout != PipActionsLayout.none
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text("Simulated player: "),
                              IconButton(
                                  onPressed: () {
                                    bool newValue = !isPlaying;
                                    pip.setIsPlaying(newValue);
                                    setState(() {
                                      isPlaying = newValue;
                                      actionResponse = "";
                                    });
                                  },
                                  icon: Icon(isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow))
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              "Obs.: Tap the simulated player button to see the PIP actions be updated on PIP mode, when you tap PIP actions on PIP mode it will reflect here too"),
                        )
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingPipController {
  final floating = Floating();
  Widget backgroundPipView = Container();
  Widget backgroundPipWidget = Container();

  FloatingPipController();

  Future<bool> isAvailable() async {
    return await floating.isPipAvailable;
  }

  Future<void> toggle(PiPStatus state) async {
    if (await status == PiPStatus.enabled) {
      await disable();
    } else if (await status == PiPStatus.disabled) {
      await enable();
    }
  }

  Future<PiPStatus> get status async {
    return await floating.pipStatus;
  }

  Future<void> disable() async {
    return await floating.cancelOnLeavePiP();
  }

  Future<PiPStatus> enable(
      {Rational aspectRatio = const Rational.landscape(),
      Rectangle<int>? sourceRectHint,
      bool isImmediate = true}) async {
    ImmediatePiP immediate =
        ImmediatePiP(aspectRatio: aspectRatio, sourceRectHint: sourceRectHint);
    OnLeavePiP onLeave =
        OnLeavePiP(aspectRatio: aspectRatio, sourceRectHint: sourceRectHint);
    return await floating.enable(isImmediate ? immediate : onLeave);
  }
}

/// Floating实现android的背景画中画功能
class BackgroundFloatingWidget extends StatelessWidget {
  final FloatingPipController floatingPipController = FloatingPipController();

  BackgroundFloatingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PiPSwitcher(
      childWhenDisabled: floatingPipController.backgroundPipView,
      childWhenEnabled: floatingPipController.backgroundPipWidget,
    );
  }
}
