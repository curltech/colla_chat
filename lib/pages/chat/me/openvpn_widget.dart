import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// OpenVpn设置
class OpenVpnWidget extends StatefulWidget with TileDataMixin {
  const OpenVpnWidget({super.key});

  @override
  State<StatefulWidget> createState() => _OpenVpnWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'openvpn';

  @override
  IconData get iconData => Icons.settings_applications;

  @override
  String get title => 'OpenVPN';

  
}

class _OpenVpnWidgetState extends State<OpenVpnWidget> {
  late OpenVPN openvpn;
  ValueNotifier<VpnStatus> status = ValueNotifier<VpnStatus>(VpnStatus.empty());
  ValueNotifier<VPNStage> stage = ValueNotifier<VPNStage>(VPNStage.unknown);
  ValueNotifier<String?> config = ValueNotifier<String?>(null);
  String? configName;
  String? configIp;

  @override
  void initState() {
    super.initState();
    openvpn = OpenVPN(
        onVpnStatusChanged: _onVpnStatusChanged,
        onVpnStageChanged: _onVpnStageChanged);
    openvpn.initialize(
      groupIdentifier: "openvpn.curltech.io",
      providerBundleIdentifier: "openvpn.curltech.io.CollaChat",
      localizedDescription: "CurlTech OpenVPN",
      lastStage: (stage) {
        this.stage.value = stage;
      },
      lastStatus: (status) {
        this.status.value = status;
      },
    );
    _getConfig();
  }

  void _onVpnStatusChanged(VpnStatus? status) {
    if (status != null) {
      this.status.value = status;
    } else {
      this.status.value = VpnStatus.empty();
    }
  }

  void _onVpnStageChanged(VPNStage? stage, String value) {
    if (stage != null) {
      this.stage.value = stage;
    } else {
      this.stage.value = VPNStage.unknown;
    }
  }

  Future<bool> _requestPermissionAndroid() async {
    if (platformParams.android) {
      return await openvpn.requestPermissionAndroid();
    }

    return false;
  }

  _getConfig() async {
    String? config = await localSecurityStorage.get('openvpn');
    this.config.value = config;
    _initConfig();
  }

  _initConfig() {
    if (config.value != null) {
      List<String> cs = config.value!.split('\n');
      if (cs.isNotEmpty) {
        configName = cs[0];
        configIp = cs[3];
      }
    }
  }

  void connect() {
    if (stage.value == VPNStage.disconnected) {
      if (config.value != null) {
        openvpn.connect(
          config.value!,
          'client',
          certIsRequired: true,
        );
      }
    }
  }

  void disconnect() {
    if (stage.value == VPNStage.connected) {
      openvpn.disconnect();
    }
  }

  Future<void> _pickConfig(
    BuildContext context,
  ) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles();
      if (xfiles.isNotEmpty) {
        config.value = await xfiles[0].readAsString();
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets();
      if (assets != null && assets.isNotEmpty) {
        Uint8List? bytes = await assets[0].originBytes;
        config.value = String.fromCharCodes(bytes!);
      }
    }
    if (config.value != null) {
      await localSecurityStorage.save('openvpn', config.value!);
      _initConfig();
    }
  }

  Widget _buildStageWidget(BuildContext context) {
    var padding = const EdgeInsets.symmetric(horizontal: 15.0);

    return ValueListenableBuilder(
        valueListenable: config,
        builder: (BuildContext context, String? value, Widget? child) {
          String title = '';
          if (configIp != null) {
            title = title + configIp!;
          }
          if (configName != null) {
            title = title + configName!;
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ListTile(
                leading: Switch(
                  value: stage.value == VPNStage.connected,
                  onChanged: (bool value) {
                    if (value) {
                      connect();
                    } else {
                      disconnect();
                    }
                  },
                ),
                title: CommonAutoSizeText(title),
                subtitle: CommonAutoSizeText(stage.value.name),
                trailing: IconButton(
                  onPressed: () {
                    _pickConfig(context);
                  },
                  icon: Icon(
                    Icons.file_open_outlined,
                    color: myself.primary,
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget _buildStatusWidget(BuildContext context) {
    var titleStyle =
        const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);
    var dataStyle =
        const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);
    Widget statusWidget = ValueListenableBuilder(
        valueListenable: status,
        builder: (BuildContext context, VpnStatus value, Widget? child) {
          var connectedOn = status.value.connectedOn;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonAutoSizeText(
                  style: titleStyle, AppLocalizations.t('Connection stats')),
              const SizedBox(
                height: 15.0,
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.download,
                        color: myself.primary,
                      ),
                      const SizedBox(
                        width: 5.0,
                      ),
                      Column(
                        children: [
                          CommonAutoSizeText(
                              style: dataStyle, AppLocalizations.t('Byte in')),
                          CommonAutoSizeText(
                              style: dataStyle, status.value.byteIn!),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.upload,
                        color: myself.primary,
                      ),
                      const SizedBox(
                        width: 5.0,
                      ),
                      Column(
                        children: [
                          CommonAutoSizeText(
                              style: dataStyle, AppLocalizations.t('Byte out')),
                          CommonAutoSizeText(
                              style: dataStyle, status.value.byteOut!),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 15.0,
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          CommonAutoSizeText(
                              style: dataStyle, AppLocalizations.t('Duration')),
                          CommonAutoSizeText(
                              style: dataStyle, status.value.duration!),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Column(
                        children: [
                          CommonAutoSizeText(
                              style: dataStyle,
                              AppLocalizations.t('Connected on')),
                          CommonAutoSizeText(
                              style: dataStyle,
                              connectedOn != null
                                  ? connectedOn.toIso8601String()
                                  : ''),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        });

    return statusWidget;
  }

  Widget _buildOpenVpnWidget(BuildContext context) {
    return Column(
      children: [
        _buildStageWidget(context),
        Container(
            padding: const EdgeInsets.all(25.0),
            child: _buildStatusWidget(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        helpPath: widget.routeName,
        child: _buildOpenVpnWidget(context));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
