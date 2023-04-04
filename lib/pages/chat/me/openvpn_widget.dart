import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/src/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// OpenVpn设置
class OpenVpnWidget extends StatefulWidget with TileDataMixin {
  const OpenVpnWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _OpenVpnWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'openvpn';

  @override
  IconData get iconData => Icons.settings_applications;

  @override
  String get title => 'OpenVpn';
}

class _OpenVpnWidgetState extends State<OpenVpnWidget> {
  late OpenVPN openvpn;
  VpnStatus? status;
  VPNStage? stage;
  String? config;
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
      localizedDescription: "CurlTech OpenVpn",
      lastStage: (stage) {
        setState(() {
          this.stage = stage;
        });
      },
      lastStatus: (status) {
        setState(() {
          this.status = status;
        });
      },
    );
  }

  void _onVpnStatusChanged(VpnStatus? status) {
    setState(() {
      this.status = status;
    });
  }

  void _onVpnStageChanged(VPNStage? stage, String value) {
    setState(() {
      this.stage = stage;
    });
  }

  void connect() {
    openvpn.connect(
      config!,
      'client',
      certIsRequired: true,
    );
  }

  void disconnect() {
    openvpn.disconnect();
  }

  Future<void> _pickConfig(
    BuildContext context,
  ) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.any);
      if (xfiles.isNotEmpty) {
        config = await xfiles[0].readAsString();
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        Uint8List? bytes = await assets[0].originBytes;
        config = String.fromCharCodes(bytes!);
      }
    }
    List<String> cs = config!.split('\n');
    if (cs.isNotEmpty) {
      configName = cs[0];
      configIp = cs[3];
    }
  }

  Widget _buildOpenVpnWidget(BuildContext context) {
    var padding = const EdgeInsets.symmetric(horizontal: 15.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ListTile(
          leading: Switch(
            value: stage == VPNStage.connected,
            onChanged: (bool value) {
              if (value) {
                connect();
              } else {
                disconnect();
              }
            },
          ),
          title: Text('$configIp(${configName!})'),
          subtitle: Text(stage!.name),
          trailing: IconButton(
            onPressed: () {
              _pickConfig(context);
            },
            icon: const Icon(Icons.file_open_outlined),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: _buildOpenVpnWidget(context));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
