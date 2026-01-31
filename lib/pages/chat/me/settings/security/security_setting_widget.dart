import 'dart:io';

import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/security/logger_console_view.dart';
import 'package:colla_chat/pages/chat/me/settings/security/password_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 安全设置组件，包括修改密码，登录选项（免登录设置），加密选项（加密算法，signal）
class SecuritySettingWidget extends StatelessWidget with DataTileMixin {
  final PasswordWidget passwordWidget = PasswordWidget();
  final LoggerConsoleView loggerConsoleView = const LoggerConsoleView();
  late final List<DataTile> securitySettingTileData;

  SecuritySettingWidget({super.key}) {
    indexWidgetProvider.define(passwordWidget);
    indexWidgetProvider.define(loggerConsoleView);
    List<DataTileMixin> mixins = [
      passwordWidget,
    ];
    if (myself.peerProfile.developerSwitch) {
      mixins.add(loggerConsoleView);
    }
    securitySettingTileData = DataTile.from(mixins);
    for (var tile in securitySettingTileData) {
      tile.dense = true;
    }
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'security_setting';

  @override
  IconData get iconData => Icons.security;

  @override
  String get title => 'Security Setting';

  

  Widget _buildBackupTileWidget(BuildContext context) {
    List<DataTile> tiles = [
      DataTile(title: 'Vacuum', prefix: Icons.compress_outlined),
      DataTile(title: 'Backup', prefix: Icons.backup),
      DataTile(title: 'Restore', prefix: Icons.restore),
      DataTile(title: 'Backup peer', prefix: Icons.backup_table),
      DataTile(title: 'Delete peer', prefix: Icons.delete_outline),
      DataTile(title: 'Restore peer', prefix: Icons.restore_page),
      DataTile(title: 'Backup attachment', prefix: Icons.copy),
      DataTile(title: 'Restore attachment', prefix: Icons.paste),
    ];
    if (myself.peerProfile.developerSwitch) {
      tiles.add(
        DataTile(title: 'Clean log', prefix: Icons.cleaning_services),
      );
    }

    return DataListView(
        itemCount: tiles.length,
        itemBuilder: (BuildContext context, int index) {
          return tiles[index];
        },
        onTap: (int index, String title, {DataTile? group, String? subtitle}) async {
          _onTap(context, index, title, group: group, subtitle: subtitle);
          return null;
        });
  }

  void _onTap(BuildContext context, int index, String title,
      {DataTile? group, String? subtitle}) {
    switch (title) {
      case 'Vacuum':
        _vacuum(context);
        break;
      case 'Backup':
        _backup(context);
        break;
      case 'Restore':
        _restore(context);
        break;
      case 'Backup peer':
        _backupPeer(context);
        break;
      case 'Delete peer':
        _deletePeer(context);
        break;
      case 'Restore peer':
        _restorePeer(context);
        break;
      case 'Backup attachment':
        _backupAttachment(context);
        break;
      case 'Restore attachment':
        _restoreAttachment(context);
        break;
      case 'Clean log':
        _cleanLog(context);
        break;
      default:
        break;
    }
  }

  Future<void> _vacuum(BuildContext context) async {
    sqlite3.vacuum();
    File file = File(appDataProvider.sqlite3Path);
    if (file.existsSync()) {
      appDataProvider.dataLength = await file.length();
      DialogUtil.info(
          context: context,
          content:
              '${AppLocalizations.t('Successfully vacuum colla.db length:')} ${appDataProvider.dataLength}');
    }
  }

  ///备份整个colla.db文件
  void _backup(BuildContext context) {
    File? file = sqlite3.backup();
    if (file != null) {
      DialogUtil.info(
          context: context,
          content:
              '${AppLocalizations.t('Successfully backup colla.db')} ${file.path}');
    }
  }

  ///从备份的colla.db.bak文件恢复
  void _restore(BuildContext context) {
    sqlite3.restore();
    DialogUtil.info(
        context: context,
        content:
            AppLocalizations.t('Successfully restore colla.db and reopen'));
  }

  ///备份当前的peer的登录信息到json文件
  Future<void> _backupPeer(BuildContext context) async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      String? filename = await myselfPeerService.backup(peerId);
      if (filename != null) {
        DialogUtil.info(
            context: context,
            content:
                '${AppLocalizations.t('Successfully backup peer filename')} $filename');
      }
    }
  }

  ///删除当前的peer和所拥有的信息
  Future<void> _deletePeer(BuildContext context) async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      bool? confirm =
          await DialogUtil.confirm(content: 'Confirm delete current peer?');
      if (confirm == true) {
        myselfPeerService.delete();
        peerClientService.delete();
        peerProfileService.delete();
        peerEndpointService.delete();
        linkmanService.delete();
        groupService.delete();
        conferenceService.delete();
        chatMessageService.delete();
        messageAttachmentService.delete();
        chatSummaryService.delete();
        groupMemberService.delete();

        myselfPeerService.logout();
        indexWidgetProvider.pop(context: context);
        indexWidgetProvider.currentMainIndex = 0;
        Application.router
            .navigateTo(context, Application.p2pLogin, replace: true);
      }
    }
  }

  ///从备份的peer的登录信息json文件恢复到数据库
  Future<void> _restorePeer(BuildContext context) async {
    List<XFile>? xfiles = await FileUtil.pickFiles(
        initialDirectory: platformParams.path,
        type: FileType.custom,
        allowedExtensions: ['json']);
    if (xfiles!=null && xfiles.isNotEmpty) {
      String backup = await xfiles.first.readAsString();
      await myselfPeerService.restore(backup);
      DialogUtil.info(
          context: context,
          content:
              '${AppLocalizations.t('Successfully restore peer filename')} ${xfiles.first.path}');
    }
  }

  ///备份当前的peer的附件
  Future<void> _backupAttachment(BuildContext context) async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      String? filename = await messageAttachmentService.backup(peerId);
      if (filename != null) {
        DialogUtil.info(
            context: context,
            content:
                '${AppLocalizations.t('Successfully backup attachment filename')} $filename');
      }
    }
  }

  ///从备份的peer的附件文件恢复
  Future<String?> _restoreAttachment(BuildContext context) async {
    String? peerId = myself.peerId;
    if (peerId != null) {
      List<XFile>? xfiles = await FileUtil.pickFiles(
          initialDirectory: platformParams.path,
          type: FileType.custom,
          allowedExtensions: ['tgz']);
      if (xfiles!=null && xfiles.isNotEmpty) {
        String? path =
            await messageAttachmentService.restore(peerId, xfiles.first.path);
        if (path != null) {
          DialogUtil.info(
              context: context,
              content:
                  '${AppLocalizations.t('Successfully restore attachment path')} $path');
        }
      }
    }
    return null;
  }

  ///清楚当前账户的日志
  void _cleanLog(BuildContext context) {
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
    DialogUtil.info(
        context: context,
        content: AppLocalizations.t('Successfully clean all log files'));
  }

  Widget _buildSettingWidget(BuildContext context) {
    Widget securitySettingTile = DataListView(
      itemCount: securitySettingTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return securitySettingTileData[index];
      },
    );
    var autoLoginTile = ListenableBuilder(
      listenable: appDataProvider,
      builder: (BuildContext context, Widget? child) {
        return CheckboxListTile(
            title: Row(children: [
              Icon(
                Icons.auto_mode,
                color: myself.secondary,
              ),
              const SizedBox(
                width: 15.0,
              ),
              AutoSizeText(AppLocalizations.t('Auto login')),
            ]),
            dense: false,
            activeColor: myself.primary,
            value: appDataProvider.autoLogin,
            onChanged: (bool? autoLogin) async {
              autoLogin = autoLogin ?? false;
              myself.autoLogin = autoLogin;
              if (autoLogin) {
                var loginName = myself.myselfPeer.loginName;
                var password = myself.password;
                await myselfPeerService.saveAutoCredential(
                    loginName, password!);
                appDataProvider.autoLogin = true;
              } else {
                await myselfPeerService.removeAutoCredential();
                appDataProvider.autoLogin = false;
              }
            });
      },
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        securitySettingTile,
        autoLoginTile,
        Expanded(child: _buildBackupTileWidget(context))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true, title: title,helpPath: routeName, child: _buildSettingWidget(context));
  }
}
