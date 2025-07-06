import 'dart:async';
import 'dart:typed_data';

import 'package:camera_linux/camera_linux.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/media_file_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/button_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

class LinuxCameraWidget extends StatefulWidget {
  final Function(XFile file)? onFile;
  final Function(Uint8List data, String mimeType)? onData;

  const LinuxCameraWidget({super.key, this.onFile, this.onData});

  @override
  State<LinuxCameraWidget> createState() => _LinuxCameraWidgetState();
}

class _LinuxCameraWidgetState extends State<LinuxCameraWidget> {
  DataListController<XFile> mediaFileController = DataListController<XFile>();
  final cameraLinuxPlugin = CameraLinux();
  ValueNotifier<bool> isCameraOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Open Default Camera
  Future<void> _initializeCamera() async {
    await cameraLinuxPlugin.initializeCamera();
    isCameraOpen.value = true;
  }

  // Capture The Image
  void _captureImage() async {
    String base64Image = await cameraLinuxPlugin.captureImage();
    Uint8List bytes = CryptoUtil.decodeBase64(base64Image);

    var name = StringUtil.uuid();
    String filename =
        await FileUtil.getTempFilename(filename: name, extension: 'jpg');
    XFile xfile =
        XFile.fromData(bytes, mimeType: ChatMessageMimeType.jpeg.name);
    mediaFileController.add(xfile);
    if (mounted) {
      DialogUtil.info(
          content: AppLocalizations.t('Picture saved at ') + (filename));
    }
  }

  // Close The Camera
  void _stopCamera() {
    cameraLinuxPlugin.stopCamera();
  }

  Icon _getCaptureIcon() {
    if (isCameraOpen.value) {
      return const Icon(
        Icons.camera,
        size: 48.0,
        color: Colors.white,
      );
    } else {
      return const Icon(
        Icons.camera,
        size: 48.0,
        color: Colors.grey,
      );
    }
  }

  Widget _buildTakeButton(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isCameraOpen,
        builder: (BuildContext context, bool isCameraOpen, Widget? child) {
          return CircleTextButton(
            onPressed: _captureImage,
            elevation: 2.0,
            backgroundColor: myself.primary,
            padding: const EdgeInsets.all(15.0),
            child: _getCaptureIcon(),
          );
        });
  }

  /// 图片显示区
  Widget _buildMediaPreviewData(BuildContext context) {
    return MediaFileWidget(mediaFileController: mediaFileController);
  }

  Widget _buildBackButton() {
    var iconButton = OverflowBar(alignment: MainAxisAlignment.start, children: [
      IconButton(
        tooltip: AppLocalizations.t('Back'),
        icon: const Icon(Icons.arrow_back_ios_new, size: 32),
        color: myself.primary,
        onPressed: () async {
          await _back();
        },
      ),
      IconButton(
        tooltip: AppLocalizations.t('Cancel'),
        icon: const Icon(Icons.cancel, size: 32),
        color: myself.primary,
        onPressed: () async {
          _stopCamera();
        },
      )
    ]);

    return iconButton;
  }

  _back() async {
    XFile? current = mediaFileController.current;
    if (widget.onData != null) {
      if (current != null) {
        var data = await current.readAsBytes();
        widget.onData!(data, current.mimeType!);
      }
    }
    if (widget.onFile != null) {
      if (current != null) {
        widget.onFile!(current);
      }
    }
    _stopCamera();
  }

  /// 相机的所有控制按钮
  Widget _buildCameraController(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: nilBox,
        ),
        Container(
            color: Colors.grey.withAlpha(AppOpacity.lgOpacity),
            child: Center(
                child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: <Widget>[
                  _buildBackButton(),
                  _buildTakeButton(context),
                  Expanded(child: _buildMediaPreviewData(context)),
                ],
              ),
            ))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCameraController(context);
  }
}
