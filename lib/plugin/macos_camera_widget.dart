import 'package:camera_macos/camera_macos_view.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathJoiner;

class MacosCameraWidget extends StatefulWidget {
  final Function(XFile file)? onFile;

  const MacosCameraWidget({super.key, this.onFile});

  @override
  MacosCameraWidgetState createState() => MacosCameraWidgetState();
}

class MacosCameraWidgetState extends State<MacosCameraWidget> {
  CameraMacOSController? macOSController;
  late CameraMacOSMode cameraMode;
  late TextEditingController durationController;
  late double durationValue;
  Uint8List? lastImagePreviewData;
  Uint8List? lastRecordedVideoData;
  GlobalKey cameraKey = GlobalKey();
  List<CameraMacOSDevice> videoDevices = [];
  String? selectedVideoDevice;

  List<CameraMacOSDevice> audioDevices = [];
  String? selectedAudioDevice;

  bool enableAudio = true;
  bool usePlatformView = false;

  @override
  void initState() {
    super.initState();
    cameraMode = CameraMacOSMode.photo;
    durationValue = 15;
    durationController = TextEditingController(text: "$durationValue");
    durationController.addListener(() {
      setState(() {
        double? textFieldContent = double.tryParse(durationController.text);
        if (textFieldContent == null) {
          durationValue = 15;
          durationController.text = "$durationValue";
        } else {
          durationValue = textFieldContent;
        }
      });
    });
  }

  String get cameraButtonText {
    String label = AppLocalizations.t("Do something");
    switch (cameraMode) {
      case CameraMacOSMode.photo:
        label = AppLocalizations.t("Take Picture");
        break;
      case CameraMacOSMode.video:
        if (macOSController?.isRecording ?? false) {
          label = AppLocalizations.t("Stop recording");
        } else {
          label = AppLocalizations.t("Record video");
        }
        break;
    }
    return label;
  }

  Future<String> get videoFilePath async => pathJoiner.join(
      (await getApplicationDocumentsDirectory()).path, "output.mp4");

  _buildVideoDeviceWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.t("Video Devices"),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButton<String>(
                  elevation: 3,
                  isExpanded: true,
                  value: selectedVideoDevice,
                  underline: Container(color: Colors.transparent),
                  items: videoDevices.map((CameraMacOSDevice device) {
                    return DropdownMenuItem(
                      value: device.deviceId,
                      child: Text(device.deviceId),
                    );
                  }).toList(),
                  onChanged: (String? newDeviceID) {
                    setState(() {
                      selectedVideoDevice = newDeviceID;
                    });
                  },
                ),
              ),
            ),
            MaterialButton(
              color: Colors.lightBlue,
              textColor: Colors.white,
              onPressed: listVideoDevices,
              child: Text(AppLocalizations.t("List video devices")),
            ),
          ],
        ),
      ],
    );
  }

  _buildAudioDeviceWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.t("Audio Devices"),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButton<String>(
                  elevation: 3,
                  isExpanded: true,
                  value: selectedAudioDevice,
                  underline: Container(color: Colors.transparent),
                  items: audioDevices.map((CameraMacOSDevice device) {
                    return DropdownMenuItem(
                      value: device.deviceId,
                      child: Text(device.deviceId),
                    );
                  }).toList(),
                  onChanged: (String? newDeviceID) {
                    setState(() {
                      selectedAudioDevice = newDeviceID;
                    });
                  },
                ),
              ),
            ),
            MaterialButton(
              color: Colors.lightBlue,
              textColor: Colors.white,
              onPressed: listAudioDevices,
              child: Text(AppLocalizations.t("List audio devices")),
            ),
          ],
        ),
      ],
    );
  }

  _buildDeviceWidget() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          _buildVideoDeviceWidget(),
          const Divider(),
          _buildAudioDeviceWidget(),
          const Divider(),
          Expanded(
            child: _buildCameraMacOSView(),
          ),
        ],
      ),
    );
  }

  _buildCameraMacOSView() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        selectedVideoDevice != null && selectedVideoDevice!.isNotEmpty
            ? CameraMacOSView(
                key: cameraKey,
                deviceId: selectedVideoDevice,
                audioDeviceId: selectedAudioDevice,
                fit: BoxFit.fill,
                cameraMode: CameraMacOSMode.photo,
                onCameraInizialized: (CameraMacOSController controller) {
                  setState(() {
                    macOSController = controller;
                  });
                },
                onCameraDestroyed: () {
                  return Text(AppLocalizations.t("Camera Destroyed!"));
                },
                enableAudio: enableAudio,
                usePlatformView: usePlatformView,
              )
            : Center(
                child: Text(AppLocalizations.t("Tap on List Devices first")),
              ),
        lastImagePreviewData != null
            ? Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Colors.lightBlue,
                      width: 10,
                    ),
                  ),
                ),
                child: Image.memory(
                  lastImagePreviewData!,
                  height: 50,
                  width: 90,
                ),
              )
            : Container(),
      ],
    );
  }

  _buildSettingWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: enableAudio,
          contentPadding: EdgeInsets.zero,
          tristate: false,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(AppLocalizations.t("Enable Audio")),
          onChanged: (bool? newValue) {
            setState(() {
              enableAudio = newValue ?? false;
            });
          },
        ),
        CheckboxListTile(
          value: usePlatformView,
          contentPadding: EdgeInsets.zero,
          tristate: false,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(AppLocalizations.t(
              "Use Platform View (Experimental - Not Working)")),
          onChanged: (bool? newValue) {
            setState(() {
              usePlatformView = newValue ?? false;
            });
          },
        ),
        Text(
          AppLocalizations.t("Camera mode"),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        RadioListTile(
          title: Text(AppLocalizations.t("Photo")),
          contentPadding: EdgeInsets.zero,
          value: CameraMacOSMode.photo,
          groupValue: cameraMode,
          onChanged: (CameraMacOSMode? newMode) {
            setState(() {
              if (newMode != null) {
                cameraMode = newMode;
              }
            });
          },
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.t("Video")),
                value: CameraMacOSMode.video,
                groupValue: cameraMode,
                onChanged: (CameraMacOSMode? newMode) {
                  setState(() {
                    if (newMode != null) {
                      cameraMode = newMode;
                    }
                  });
                },
              ),
            ),
            Visibility(
              visible: cameraMode == CameraMacOSMode.video,
              child: Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.t("Video Length"),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _buildCameraWidget() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.t("Settings"),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 90,
                child: _buildSettingWidget(),
              ),
              const Spacer(flex: 10),
            ],
          ),
          Container(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MaterialButton(
                color: Colors.red,
                textColor: Colors.white,
                onPressed: destroyCamera,
                child: Builder(
                  builder: (context) {
                    String buttonText = AppLocalizations.t("Destroy");
                    if (macOSController != null &&
                        macOSController!.isDestroyed) {
                      buttonText = AppLocalizations.t("Reinitialize");
                    }
                    return Text(buttonText);
                  },
                ),
              ),
              MaterialButton(
                color: Colors.lightBlue,
                textColor: Colors.white,
                onPressed: onCameraButtonTap,
                child: Text(cameraButtonText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> startRecording() async {
    try {
      String urlPath = await videoFilePath;
      await macOSController!.recordVideo(
        maxVideoDuration: durationValue,
        url: urlPath,
        enableAudio: enableAudio,
        onVideoRecordingFinished:
            (CameraMacOSFile? result, CameraMacOSException? exception) {
          setState(() {});
          if (exception != null) {
            showAlert(message: exception.toString());
          } else if (result != null) {
            showAlert(
              title: "SUCCESS",
              message: "Video saved at ${result.url}",
            );
          }
        },
      );
    } catch (e) {
      showAlert(message: e.toString());
    } finally {
      setState(() {});
    }
  }

  Future<void> listVideoDevices() async {
    try {
      List<CameraMacOSDevice> videoDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
      setState(() {
        this.videoDevices = videoDevices;
        if (videoDevices.isNotEmpty) {
          selectedVideoDevice = videoDevices.first.deviceId;
        }
      });
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> listAudioDevices() async {
    try {
      List<CameraMacOSDevice> audioDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.audio,
      );
      setState(() {
        this.audioDevices = audioDevices;
        if (audioDevices.isNotEmpty) {
          selectedAudioDevice = audioDevices.first.deviceId;
        }
      });
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  void changeCameraMode() {
    setState(() {
      cameraMode = cameraMode == CameraMacOSMode.photo
          ? CameraMacOSMode.video
          : CameraMacOSMode.photo;
    });
  }

  Future<void> destroyCamera() async {
    try {
      if (macOSController != null) {
        if (macOSController!.isDestroyed) {
          setState(() {
            cameraKey = GlobalKey();
          });
        } else {
          await macOSController?.destroy();
          setState(() {});
        }
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> onCameraButtonTap() async {
    try {
      if (macOSController != null) {
        switch (cameraMode) {
          case CameraMacOSMode.photo:
            CameraMacOSFile? imageData = await macOSController!.takePicture();
            if (imageData != null) {
              setState(() {
                lastImagePreviewData = imageData.bytes;
              });
              showAlert(
                title: "SUCCESS",
                message: "Image successfully created",
              );
              //widget.onFile!(file);
            }
            break;
          case CameraMacOSMode.video:
            if (macOSController!.isRecording) {
              CameraMacOSFile? videoData =
                  await macOSController!.stopRecording();
              if (videoData != null) {
                setState(() {
                  lastRecordedVideoData = videoData.bytes;
                });
                showAlert(
                  title: "SUCCESS",
                  message: "Video saved at ${videoData.url}",
                );
                //widget.onFile!(file);
              }
            } else {
              startRecording();
            }
            break;
        }
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> showAlert({
    String title = "ERROR",
    String message = "",
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.t(title)),
          content: Text(AppLocalizations.t(message)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.t('Ok')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 90, child: _buildDeviceWidget()),
        _buildCameraWidget(),
      ],
    );
  }
}
