import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/download_file_util.dart';
import 'package:colla_chat/tool/sherpa/sherpa_config_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

class SherpaInstallWidget extends StatelessWidget with TileDataMixin {
  //'sherpa-onnx-conformer-zh','sherpa-onnx-vits-zh-ll'
  TextEditingController modelNameController = TextEditingController();
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
      modelNameController.text,
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

  Widget _buildModelWidget(BuildContext context) {
    List<TileData> tiles = [];
    List<String> asrModelNames =
        SherpaConfigUtil.sherpaAsrModelDownloadUrl.keys.toList();
    for (String modelName in asrModelNames) {
      tiles.add(TileData(
          title: modelName,
          selected: modelNameController.text == title,
          onTap: (int index, String title, {String? subtitle}) {
            modelNameController.text = title;
            Navigator.pop(context);
          }));
    }
    Map<TileData, List<TileData>> groupTileData = {};
    groupTileData[TileData(title: 'asr')] = tiles;

    List<String> ttsModelNames =
        SherpaConfigUtil.sherpaTtsModelDownloadUrl.keys.toList();
    for (String modelName in ttsModelNames) {
      tiles.add(TileData(
          title: modelName,
          selected: modelNameController.text == title,
          onTap: (int index, String title, {String? subtitle}) {
            modelNameController.text = title;
            Navigator.pop(context);
          }));
    }
    groupTileData[TileData(title: 'tts')] = tiles;

    Widget child = GroupDataListView(tileData: groupTileData);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 15.0,
        ),
        CommonAutoSizeTextFormField(
            controller: modelNameController,
            labelText: AppLocalizations.t('Sherpa model'),
            suffix: IconButton(
                onPressed: () {
                  DialogUtil.show(
                      title: Text(AppLocalizations.t('Select')),
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(child: child);
                      });
                },
                icon: Icon(
                  Icons.select_all_outlined,
                  color: myself.primary,
                ))),
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
                  ),
                  tooltip: AppLocalizations.t('Save'),
                ),
              ),
            );
            children.add(_buildModelWidget(context));
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
