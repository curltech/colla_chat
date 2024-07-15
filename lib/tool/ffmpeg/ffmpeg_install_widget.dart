import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/download_file_util.dart';
import 'package:colla_chat/tool/ffmpeg/ffmpeg_helper.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

class FFMpegInstallWidget extends StatefulWidget {
  Function()? onDownloadComplete;

  FFMpegInstallWidget({super.key, this.onDownloadComplete});

  @override
  State<FFMpegInstallWidget> createState() => _FFMpegInstallWidgetState();
}

class _FFMpegInstallWidgetState extends State<FFMpegInstallWidget> {
  ValueNotifier<bool> ffmpegPresent = ValueNotifier<bool>(false);
  ValueNotifier<DownloadProgress> downloadProgress =
      ValueNotifier<DownloadProgress>(DownloadProgress(
    downloaded: 0,
    fileSize: 0,
    phase: DownloadProgressPhase.inactive,
  ));
  TextEditingController controller = TextEditingController();

  Future<bool> checkFFMpeg() async {
    ffmpegPresent.value = await FFMpegHelper.initialize();

    return ffmpegPresent.value;
  }

  Future<void> setupFFMpeg() async {
    if (platformParams.windows) {
      bool success = await FFMpegHelper.setupFFMpegOnWindows(
        onProgress: (DownloadProgress progress) {
          downloadProgress.value = progress;
        },
      );
      ffmpegPresent.value = success;
      widget.onDownloadComplete?.call();
    }
  }

  Widget _buildInstallWidget(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle(
        maximumSize: const Size(200.0, 56.0), backgroundColor: myself.primary);
    return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            style: style,
            label: const Text('Setup FFMpeg'),
            icon: const Icon(Icons.download),
            onPressed: setupFFMpeg,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 360,
            child: ValueListenableBuilder(
              valueListenable: downloadProgress,
              builder: (BuildContext context, DownloadProgress value, _) {
                double? prog;
                if ((value.downloaded != 0) && (value.fileSize != 0)) {
                  prog = value.downloaded / value.fileSize;
                } else {
                  prog = 0;
                }
                if (value.phase == DownloadProgressPhase.decompressing) {
                  prog = null;
                }
                if (value.phase == DownloadProgressPhase.inactive) {
                  return const SizedBox.shrink();
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value.phase.name),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(value: prog),
                  ],
                );
              },
            ),
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ffmpegPresent,
      builder: (BuildContext context, bool ffmpegPresent, Widget? child) {
        List<Widget> children = [];
        controller.text = FFMpegHelper.ffmpegInstallationPath ?? '';
        children.add(
          CommonAutoSizeTextFormField(
              labelText: 'FFMpeg installation path',
              controller: controller,
              hintText: 'FFMpeg installation path',
              suffix: IconButton(
                  onPressed: () {
                    FFMpegHelper.ffmpegInstallationPath = controller.text;
                  },
                  icon: Icon(
                    Icons.save,
                    color: myself.primary,
                  ))),
        );

        if (!ffmpegPresent) {
          if (platformParams.windows) {
            children.addAll([
              const SizedBox(height: 20),
              _buildInstallWidget(context),
            ]);
          }
          if (platformParams.linux) {
            children.add(const CommonAutoSizeText(
                'FFmpeg installation required by user.\nsudo apt-get install ffmpeg\nsudo snap install ffmpeg'));
          }
        }
        return Container(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }
}
