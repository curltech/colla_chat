import 'dart:core';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
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
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pLoginWidget extends StatelessWidget {
  //是否指定登录用户，如果指定将不能修改登录名，表示只做用户验证，否则做用户登录
  final String? credential;

  //当指定用户做验证的时候不为空
  final void Function(String? result)? onAuthenticate;

  P2pLoginWidget({super.key, this.credential, this.onAuthenticate}) {
    _init();
  }

  late final FormInputController formInputController;

  _init() async {
    bool isAuth = (this.credential != null);
    final List<PlatformDataField> p2pLoginDataFields = [];
    p2pLoginDataFields.add(PlatformDataField(
      name: 'credential',
      label: 'Credential(Mobile/Email/Name)',
      readOnly: isAuth,
      cancel: !isAuth,
      prefixIcon: !isAuth
          ? TextButton.icon(
              icon: const Icon(Icons.person, color: Colors.yellowAccent),
              onPressed: () async {
                await DialogUtil.show(builder: _buildMyselfPeers);
                var myselfPeer = myselfPeerController.current;
                if (myselfPeer != null) {
                  String? credential = myselfPeer.loginName;
                  if (StringUtil.isNotEmpty(credential)) {
                    formInputController.setValue('credential', credential);
                  }
                }
              },
              label: CommonAutoSizeText(
                AppLocalizations.t('Select'),
                style: const TextStyle(color: Colors.yellowAccent),
              ),
            )
          : null,
    ));
    p2pLoginDataFields.add(PlatformDataField(
      name: 'password',
      label: 'Password',
      inputType: InputType.password,
      cancel: true,
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      ),
    ));
    formInputController = FormInputController(p2pLoginDataFields);
    String? credential = formInputController.getValue('credential');
    if (credential == null) {
      credential = this.credential;
      String? lastCredentialName = await myselfPeerService.lastCredentialName();
      if (lastCredentialName != null) {
        MyselfPeer? myselfPeer =
            await myselfPeerService.findOneByLogin(lastCredentialName);
        if (myselfPeer != null) {
          credential ??= lastCredentialName;
          if (StringUtil.isNotEmpty(credential)) {
            formInputController.setValue('credential', credential);
          }
          return;
        }
      }
    }
  }

  TileData? _buildMyselfPeerTile(int index) {
    TileData? tileData;
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
    if (myselfPeers.isNotEmpty) {
      MyselfPeer myselfPeer = myselfPeers[index];
      tileData = TileData(
        title: myselfPeer.loginName,
        subtitle: myselfPeer.peerId,
        titleTail: myselfPeer.name,
        prefix: myselfPeer.avatarImage,
        selected: myselfPeerController.currentIndex == index,
        suffix: IconButton(
          onPressed: () async {
            bool? confirm =
                await DialogUtil.confirm(content: 'Do you want delete peer');
            if (confirm == null || confirm == false) {
              return;
            }
            chatMessageService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            messageAttachmentService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            peerProfileService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            chatSummaryService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            linkmanService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            groupService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            groupMemberService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            conferenceService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            peerClientService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            peerEndpointService
                .delete(where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
            myselfPeerService
                .delete(where: 'peerId=?', whereArgs: [myselfPeer.peerId]);
            myselfPeerController.delete(index: index);
          },
          icon: const Icon(Icons.clear),
        ),
      );
    }

    return tileData;
  }

  Widget _buildMyselfPeers(BuildContext context) {
    return Dialog(
        child: Column(children: [
      AppBarWidget(
        title: CommonAutoSizeText(AppLocalizations.t('Select login peer')),
      ),
      const SizedBox(
        height: 5.0,
      ),
      Obx(() {
        return DataListView(
          onTap: (int index, String title,
              {TileData? group, String? subtitle}) {
            myselfPeerController.setCurrentIndex = index;
            Navigator.pop(context);
          },
          itemCount: myselfPeerController.data.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildMyselfPeerTile(index);
          },
        );
      })
    ]));
  }

  //验证
  _auth(Map<String, dynamic> values) async {
    String? credential = values[credentialName];
    String? password = values[passwordName];
    if (credential == null) {
      DialogUtil.error(content: 'Must have node credential');
      return;
    }
    if (password == null) {
      DialogUtil.error(content: 'Must have node password');
      return;
    }
    try {
      DialogUtil.loadingShow();
      String? loginStatus = await myselfPeerService.auth(credential, password);
      DialogUtil.loadingHide();
      if (loginStatus != null) {
        DialogUtil.error(content: AppLocalizations.t(loginStatus));
      }
      if (onAuthenticate != null) {
        onAuthenticate!(loginStatus);
      }
    } catch (e) {
      if (onAuthenticate != null) {
        onAuthenticate!(e.toString());
      } else {
        DialogUtil.error(content: e.toString());
      }
    }
  }

  ///登录
  _login(BuildContext context, Map<String, dynamic> values) async {
    String? credential = values[credentialName];
    String? password = values[passwordName];
    if (credential == null) {
      DialogUtil.error(content: 'Must have node credential');
      return;
    }
    if (password == null) {
      DialogUtil.error(content: 'Must have node password');
      return;
    }
    try {
      DialogUtil.loadingShow();
      String? loginStatus = await myselfPeerService.login(credential, password);
      DialogUtil.loadingHide();

      if (loginStatus == null) {
        ///连接篇p2p的节点，把自己的信息注册上去
        myselfPeerService.connect();
        if (myself.autoLogin) {
          myselfPeerService.saveAutoCredential(credential, password);
        }

        Application.router
            .navigateTo(context, Application.index, replace: true);
      } else {
        DialogUtil.error(content: AppLocalizations.t(loginStatus));
      }
    } catch (e) {
      DialogUtil.error(content: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: appDataProvider.portraitSize.height * 0.1,
      ),
      ImageUtil.buildImageWidget(
        imageContent: 'assets/image/colla.png',
        height: AppImageSize.xlSize,
        width: AppImageSize.xlSize,
      ),
      CommonAutoSizeText(
        AppLocalizations.t('Secure your collaboration'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.cyan,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      SizedBox(
        height: appDataProvider.portraitSize.height * 0.1,
      ),
      Expanded(
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: FormInputWidget(
                mainAxisAlignment: MainAxisAlignment.start,
                // height: appDataProvider.portraitSize.height * 0.3,
                spacing: 10.0,
                onOk: (Map<String, dynamic> values) async {
                  if (credential == null) {
                    await _login(context, values);
                  } else {
                    await _auth(values);
                  }
                },
                okLabel: credential == null ? 'Login' : 'Auth',
                controller: formInputController,
              )))
    ]);
  }
}
