import 'dart:io';

import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/security/logger_console_view.dart';
import 'package:colla_chat/pages/chat/me/settings/security/password_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

/// 安全设置组件，包括修改密码，登录选项（免登录设置），加密选项（加密算法，signal）
class SecuritySettingWidget extends StatefulWidget with TileDataMixin {
  final PasswordWidget passwordWidget = const PasswordWidget();
  final LoggerConsoleView loggerConsoleView = const LoggerConsoleView();
  late final List<TileData> securitySettingTileData;

  SecuritySettingWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(passwordWidget);
    indexWidgetProvider.define(loggerConsoleView);
    List<TileDataMixin> mixins = [
      passwordWidget,
      loggerConsoleView,
    ];
    securitySettingTileData = TileData.from(mixins);
    for (var tile in securitySettingTileData) {
      tile.dense = true;
    }
  }

  @override
  State<StatefulWidget> createState() => _SecuritySettingWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'security_setting';

  @override
  IconData get iconData => Icons.security;

  @override
  String get title => 'Security Setting';
}

class _SecuritySettingWidgetState extends State<SecuritySettingWidget> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildBackupTileWidget() {
    List<TileData> tiles = [
      TileData(title: 'Backup', prefix: Icons.backup),
      TileData(title: 'Restore', prefix: Icons.restore),
      TileData(title: 'Backup peer', prefix: Icons.backup_table),
      TileData(title: 'Restore peer', prefix: Icons.restore_page),
      TileData(title: 'Backup attachment', prefix: Icons.copy),
      TileData(title: 'Restore attachment', prefix: Icons.paste),
      TileData(title: 'Clean log', prefix: Icons.cleaning_services),
    ];

    return DataListView(tileData: tiles, onTap: _onTap);
  }

  _onTap(int index, String title, {TileData? group, String? subtitle}) {
    switch (title) {
      case 'Backup':
        _backup();
        break;
      case 'Restore':
        _restore();
        break;
      case 'Backup peer':
        _backupPeer();
        break;
      case 'Restore peer':
        _restorePeer();
        break;
      case 'Backup attachment':
        _backupAttachment();
        break;
      case 'Restore attachment':
        _restoreAttachment();
        break;
      case 'Clean log':
        _cleanLog();
        break;
      default:
        break;
    }
  }

  ///备份整个colla.db文件
  _backup() {
    File? file = sqlite3.backup();
    if (file != null) {
      if (mounted) {
        DialogUtil.info(context,
            content:
                '${AppLocalizations.t('Successfully backup colla.db')} ${file.path}');
      }
    }
  }

  ///从备份的colla.db.bak文件恢复
  void _restore() {
    sqlite3.restore();
    if (mounted) {
      DialogUtil.info(context,
          content:
              AppLocalizations.t('Successfully restore colla.db and reopen'));
    }
  }

  ///备份当前的peer的登录信息到json文件
  Future<void> _backupPeer() async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      String? filename = await myselfPeerService.backup(peerId);
      if (filename != null) {
        if (mounted) {
          DialogUtil.info(context,
              content:
                  '${AppLocalizations.t('Successfully backup peer filename')} $filename');
        }
      }
    }
  }

  ///从备份的peer的登录信息json文件恢复到数据库
  Future<void> _restorePeer() async {
    List<XFile> xfiles = await FileUtil.selectFiles(
        initialDirectory: platformParams.path, allowedExtensions: ['json']);
    if (xfiles.isNotEmpty) {
      String backup = await xfiles.first.readAsString();
      await myselfPeerService.restore(backup);
      if (mounted) {
        DialogUtil.info(context,
            content:
                '${AppLocalizations.t('Successfully restore peer filename')} ${xfiles.first.path}');
      }
    }
  }

  ///备份当前的peer的附件
  Future<void> _backupAttachment() async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      String? filename = await messageAttachmentService.backup(peerId);
      if (filename != null) {
        if (mounted) {
          DialogUtil.info(context,
              content:
                  '${AppLocalizations.t('Successfully backup attachment filename')} $filename');
        }
      }
    }
  }

  ///从备份的peer的附件文件恢复
  Future<String?> _restoreAttachment() async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      List<XFile> xfiles = await FileUtil.selectFiles(
          initialDirectory: platformParams.path, allowedExtensions: ['tgz']);
      if (xfiles.isNotEmpty) {
        String? path =
            await messageAttachmentService.restore(peerId, xfiles.first.path);
        if (path != null) {
          if (mounted) {
            DialogUtil.info(context,
                content:
                    '${AppLocalizations.t('Successfully restore attachment path')} $path');
          }
        }
      }
    }
  }

  ///清楚当前账户的日志
  void _cleanLog() {
    List<FileSystemEntity> files =
        PathUtil.listFile(platformParams.path, end: '.log');
    if (files.isNotEmpty) {
      for (var file in files) {
        file.deleteSync();
      }
    }
    files = PathUtil.listFile(myself.myPath, end: '.log');
    if (files.isNotEmpty) {
      for (var file in files) {
        file.deleteSync();
      }
    }
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Successfully clean all log files'));
    }
  }

  Widget _buildSettingWidget(BuildContext context) {
    Widget securitySettingTile =
        DataListView(tileData: widget.securitySettingTileData);
    var autoLoginTile = CheckboxListTile(
        title: Row(children: [
          Icon(
            Icons.auto_mode,
            color: myself.secondary,
          ),
          const SizedBox(
            width: 15.0,
          ),
          CommonAutoSizeText(AppLocalizations.t('Auto login')),
        ]),
        dense: false,
        activeColor: myself.primary,
        value: appDataProvider.autoLogin,
        onChanged: (bool? autoLogin) async {
          autoLogin = autoLogin ?? false;
          if (myself.autoLogin == autoLogin) {
            return;
          }
          myself.autoLogin = autoLogin;
          if (autoLogin) {
            var loginName = myself.myselfPeer.loginName;
            var password = myself.password;
            await myselfPeerService.saveAutoCredential(loginName, password!);
            appDataProvider.autoLogin = true;
          } else {
            await myselfPeerService.removeAutoCredential();
            appDataProvider.autoLogin = false;
          }
        });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        securitySettingTile,
        autoLoginTile,
        _buildBackupTileWidget()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: _buildSettingWidget(context));
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
