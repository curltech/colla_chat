import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class ClientConnectWidget extends StatefulWidget with TileDataMixin {
  //
  const ClientConnectWidget({
    Key? key,
  }) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'client_connect';

  @override
  IconData get iconData => Icons.screen_rotation;

  @override
  String get title => 'ClientConnect';

  @override
  State<StatefulWidget> createState() => _ClientConnectWidgetState();
}

class _ClientConnectWidgetState extends State<ClientConnectWidget> {
  final List<PlatformDataField> _connectDataField = [
    PlatformDataField(
      name: 'uri',
      label: 'Uri',
    ),
    PlatformDataField(
      name: 'token',
      label: 'Token',
    ),
    PlatformDataField(
      name: 'shareKey',
      label: 'ShareKey',
    ),
    PlatformDataField(
      name: 'simulcast',
      label: 'Simulcast',
      inputType: InputType.toggle,
      dataType: DataType.bool,
    ),
    PlatformDataField(
      name: 'adaptiveStream',
      label: 'AdaptiveStream',
      inputType: InputType.toggle,
      dataType: DataType.bool,
    ),
    PlatformDataField(
      name: 'dynacast',
      label: 'Dynacast',
      inputType: InputType.toggle,
      dataType: DataType.bool,
    ),
    PlatformDataField(
      name: 'fastConnect',
      label: 'FastConnect',
      inputType: InputType.toggle,
      dataType: DataType.bool,
    ),
    PlatformDataField(
      name: 'e2ee',
      label: 'E2ee',
      inputType: InputType.toggle,
      dataType: DataType.bool,
    ),
  ];
  late FormInputController controller = FormInputController(_connectDataField);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (platformParams.android) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      logger.warning('Bluetooth Permission disabled');
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      logger.warning('Bluetooth Connect Permission disabled');
    }

    status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      logger.warning('Camera Permission disabled');
    }

    status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      logger.warning('Microphone Permission disabled');
    }
  }

  Future<void> _connect(Map<String, dynamic> values) async {
    _busy = true;
    String uri = values['uri'];
    String token = values['token'];
    String shareKey = values['shareKey'];
    bool simulcast = values['simulcast'];
    bool adaptiveStream = values['adaptiveStream'];
    bool dynacast = values['dynacast'];
    bool fastConnect = values['fastConnect'];
    bool e2ee = values['e2ee'];
    try {
      logger.warning('Connecting with url: $uri, token: $token...');
      final room = Room();

      //房间的监听器，用于房间页面
      final listener = room.createListener();
      E2EEOptions? e2eeOptions;
      if (e2ee) {
        final keyProvider = await BaseKeyProvider.create();
        e2eeOptions = E2EEOptions(keyProvider: keyProvider);
        await keyProvider.setKey(shareKey);
      }

      await room.connect(
        uri,
        token,
        roomOptions: RoomOptions(
          adaptiveStream: adaptiveStream,
          dynacast: dynacast,
          defaultAudioPublishOptions:
              const AudioPublishOptions(name: 'custom_audio_track_name'),
          defaultVideoPublishOptions: VideoPublishOptions(
            simulcast: simulcast,
          ),
          defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
              useiOSBroadcastExtension: true,
              params: VideoParameters(
                  dimensions: VideoDimensionsPresets.h1080_169,
                  encoding: VideoEncoding(
                    maxBitrate: 3 * 1000 * 1000,
                    maxFramerate: 15,
                  ))),
          e2eeOptions: e2eeOptions,
          defaultCameraCaptureOptions: const CameraCaptureOptions(
              maxFrameRate: 30,
              params: VideoParameters(
                  dimensions: VideoDimensionsPresets.h720_169,
                  encoding: VideoEncoding(
                    maxBitrate: 2 * 1000 * 1000,
                    maxFramerate: 30,
                  ))),
        ),
        fastConnectOptions: fastConnect
            ? FastConnectOptions(
                microphone: const TrackOption(enabled: true),
                camera: const TrackOption(enabled: true),
              )
            : null,
      );
      indexWidgetProvider.push('room');
    } catch (error) {
      print('Could not connect $error');
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Widget _buildConnectParasWidget() {
    return FormInputWidget(
      mainAxisAlignment: MainAxisAlignment.start,
      height: appDataProvider.portraitSize.height * 0.5,
      spacing: 10.0,
      onOk: (Map<String, dynamic> values) async {
        await _connect(values);
      },
      okLabel: 'Connect',
      controller: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    var connectWidget = AppBarView(
        title: widget.title,
        withLeading: true,
        child: Column(children: <Widget>[_buildConnectParasWidget()]));

    return connectWidget;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
