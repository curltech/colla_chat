import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/download_file_util.dart';
import 'package:colla_chat/tool/sherpa/sherpa_config_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class SherpaInstallWidget extends StatelessWidget with TileDataMixin {
  //'sherpa-onnx-conformer-zh','sherpa-onnx-vits-zh-ll'
  ValueNotifier<String?> modelName = ValueNotifier<String?>(null);
  Function()? onDownloadComplete;

  SherpaInstallWidget({super.key, this.onDownloadComplete}) {
    checkSherpa();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sherpa_install';

  @override
  IconData get iconData => Icons.install_desktop_outlined;

  @override
  String get title => 'SherpaInstall';

  ValueNotifier<bool> sherpaPresent = ValueNotifier<bool>(false);
  ValueNotifier<DownloadProgress> downloadProgress =
      ValueNotifier<DownloadProgress>(DownloadProgress(
    downloaded: 0,
    fileSize: 0,
    phase: DownloadProgressPhase.inactive,
  ));
  TextEditingController controller = TextEditingController();

  Future<bool> checkSherpa() async {
    sherpaPresent.value = await SherpaConfigUtil.initializeSherpaModel();

    return sherpaPresent.value;
  }

  Future<void> setupSherpaModel() async {
    bool success = await SherpaConfigUtil.setupSherpaModel(
      modelName.value!,
      onProgress: (DownloadProgress progress) {
        downloadProgress.value = progress;
      },
    );
    sherpaPresent.value = success;
    onDownloadComplete?.call();
  }

  Widget _buildInstallWidget(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle(
        maximumSize: const Size(200.0, 56.0), backgroundColor: myself.primary);
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextButton.icon(
            style: style,
            label: Text(AppLocalizations.t('Setup sherpa')),
            icon: const Icon(Icons.download),
            onPressed: setupSherpaModel,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: appDataProvider.secondaryBodyWidth,
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
                    Text(AppLocalizations.t(value.phase.name)),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(value: prog),
                  ],
                );
              },
            ),
          ),
        ]);
  }

  Widget _buildModelWidget() {
    List<String> asrModelNames =
        SherpaConfigUtil.sherpaAsrModelDownloadUrl.keys.toList();
    List<String> ttsModelNames =
        SherpaConfigUtil.sherpaTtsModelDownloadUrl.keys.toList();
    List<String> modelNames = [];
    modelNames.addAll(asrModelNames);
    modelNames.addAll(ttsModelNames);
    var items = <DropdownMenuItem<String>>[];
    for (String modelName in modelNames) {
      items.add(DropdownMenuItem(
        value: modelName,
        child: Text(modelName),
      ));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 15.0,
        ),
        CommonAutoSizeText(AppLocalizations.t('Sherpa model')),
        ValueListenableBuilder(
          valueListenable: modelName,
          builder: (BuildContext context, value, Widget? child) {
            return DropdownButton(
                value: modelName.value,
                items: items,
                onChanged: (Object? item) {
                  modelName.value = item.toString();
                });
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: title,
        child: ValueListenableBuilder(
          valueListenable: sherpaPresent,
          builder: (BuildContext context, bool sherpaPresent, Widget? child) {
            List<Widget> children = [];
            controller.text =
                SherpaConfigUtil.sherpaModelInstallationPath ?? '';
            children.add(
              CommonAutoSizeTextFormField(
                  labelText: AppLocalizations.t('Sherpa installation path'),
                  controller: controller,
                  hintText: AppLocalizations.t('Sherpa installation path'),
                  suffix: IconButton(
                      onPressed: () {
                        SherpaConfigUtil.sherpaModelInstallationPath =
                            controller.text;
                      },
                      icon: Icon(
                        Icons.save,
                        color: myself.primary,
                      ))),
            );
            children.add(_buildModelWidget());
            children.addAll([
              const SizedBox(height: 20),
              Expanded(child: _buildInstallWidget(context)),
            ]);

            return Container(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            );
          },
        ));
  }
}
