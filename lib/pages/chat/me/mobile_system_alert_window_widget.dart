import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/share_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:system_alert_window/system_alert_window.dart';

const String mainSystemAlertWindowPort = 'MainSystemAlertWindow';

/// 移动版的系统警告窗口的主窗口部分
class MobileSystemAlertWindowWidget extends StatelessWidget with TileDataMixin {
  MobileSystemAlertWindowWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'mobile_system_alert_window';

  @override
  IconData get iconData => Icons.sensor_window_outlined;

  @override
  String get title => 'Mobile system alert window';

  final RxString platformVersion = 'Unknown'.obs;
  final RxBool isShowingWindow = false.obs;
  final RxBool isUpdatedWindow = false.obs;
  final SystemWindowPrefMode prefMode = SystemWindowPrefMode.OVERLAY;
  final receivePort = ReceivePort();

  void init() {
    _initPlatformState();
    _requestPermissions();
    final res = IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      mainSystemAlertWindowPort,
    );
    logger.i("$res: OVERLAY");
    receivePort.listen((message) {
      logger.i("message from OVERLAY: $message");
    });
  }

  /// 平台消息是异步的
  Future<void> _initPlatformState() async {
    await SystemAlertWindow.enableLogs(true);
    try {
      platformVersion.value = (await SystemAlertWindow.platformVersion)!;
    } on PlatformException {
      platformVersion.value = 'Failed to get platform version.';
    }
  }

  Future<void> _requestPermissions() async {
    await SystemAlertWindow.requestPermissions(prefMode: prefMode);
  }

  void _showOverlayWindow(BuildContext context) async {
    if (!isShowingWindow.value) {
      await SystemAlertWindow.sendMessageToOverlay('show system window');
      SystemAlertWindow.showSystemWindow(
          height: 200,
          width: MediaQuery.of(context).size.width.floor(),
          gravity: SystemWindowGravity.CENTER,
          prefMode: prefMode);
      isShowingWindow.value = true;
    }
  }

  void _updateOverlayWindow(BuildContext context) async {
    if (!isUpdatedWindow.value) {
      await SystemAlertWindow.sendMessageToOverlay('update system window');
      SystemAlertWindow.updateSystemWindow(
          height: 200,
          width: MediaQuery.of(context).size.width.floor(),
          gravity: SystemWindowGravity.CENTER,
          prefMode: prefMode
          // isDisableClicks: true
          );
      isUpdatedWindow.value = true;
      SystemAlertWindow.sendMessageToOverlay(isUpdatedWindow.value);
    }
  }

  void _closeOverlayWindow(BuildContext context) async {
    isShowingWindow.value = false;
    isUpdatedWindow.value = false;
    SystemAlertWindow.sendMessageToOverlay(isUpdatedWindow.value);
    SystemAlertWindow.closeSystemWindow(prefMode: prefMode);
  }

  @override
  Widget build(BuildContext context) {
    var overlayApp = AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      rightWidgets: [
        if (!isShowingWindow.value)
          IconButton(
              onPressed: () {
                _showOverlayWindow(context);
              },
              icon: Icon(Icons.show_chart)),
        if (isShowingWindow.value && !isUpdatedWindow.value)
          IconButton(
              onPressed: () {
                _updateOverlayWindow(context);
              },
              icon: Icon(Icons.update)),
        if (isShowingWindow.value && isUpdatedWindow.value)
          IconButton(
              onPressed: () {
                _closeOverlayWindow(context);
              },
              icon: Icon(Icons.close)),
        IconButton(
            onPressed: () {
              SystemAlertWindow.sendMessageToOverlay("message from main");
            },
            icon: Icon(Icons.send)),
        IconButton(
            onPressed: () async {
              String? logFilePath = await SystemAlertWindow.getLogFile;
              if (logFilePath != null && logFilePath.isNotEmpty) {
                final files = <XFile>[];
                files.add(XFile(logFilePath, name: "Log File from SAW"));
                await ShareUtil.share(files: files);
              } else {
                logger.i("Path is empty");
              }
            },
            icon: Icon(Icons.share)),
      ],
      child: Center(
        child: Text('Running on: ${platformVersion.value}\n'),
      ),
    );

    return overlayApp;
  }
}

/// 移动版的系统警告窗口的overlay部分
class MobileOverlayWidget extends StatefulWidget {
  const MobileOverlayWidget({super.key});

  @override
  State<MobileOverlayWidget> createState() => _MobileOverlayWidgetState();
}

class _MobileOverlayWidgetState extends State<MobileOverlayWidget> {
  SendPort? mainAppPort;
  bool update = false;

  @override
  void initState() {
    super.initState();

    SystemAlertWindow.overlayListener.listen((event) {
      logger.i("$event in overlay");
      if (event is bool) {
        setState(() {
          update = event;
        });
      }
    });
  }

  void callBackFunction(String tag) {
    mainAppPort ??= IsolateNameServer.lookupPortByName(
      mainSystemAlertWindowPort,
    );
    mainAppPort?.send('Date: ${DateTime.now()}');
    mainAppPort?.send(tag);
  }

  Widget _buildOverlayWidget() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 60,
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(update ? "outgoing" : "Incoming",
                          style:
                              TextStyle(fontSize: 10, color: Colors.black45)),
                      Text(
                        "123456",
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    overlayColor: WidgetStatePropertyAll(Colors.transparent),
                  ),
                  onPressed: () {
                    callBackFunction("Close");
                    SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2.3,
                    margin: EdgeInsets.only(left: 30),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        color: update ? Colors.grey : Colors.deepOrange),
                    child: Center(
                      child: Text(
                        "Close",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Text(
              update ? "clicks Disabled" : "Body",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
            ),
            onPressed: () {
              callBackFunction("Action");
            },
            child: Container(
              padding: EdgeInsets.all(12),
              height: (MediaQuery.of(context).size.height) / 3.5,
              width: MediaQuery.of(context).size.width / 1.05,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  color: update ? Colors.grey : Colors.deepOrange),
              child: Center(
                child: Text(
                  "Action",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildOverlayWidget();
  }
}
