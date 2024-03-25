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

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pLoginWidget extends StatefulWidget {
  //是否指定登录用户，如果指定将不能修改登录名，表示只做用户验证，否则做用户登录
  final String? credential;

  //当指定用户做验证的时候不为空
  final void Function(String? result)? onAuthenticate;

  const P2pLoginWidget({super.key, this.credential, this.onAuthenticate});

  @override
  State<StatefulWidget> createState() => _P2pLoginWidgetState();
}

class _P2pLoginWidgetState extends State<P2pLoginWidget> {
  late final FormInputController controller;
  ValueNotifier<bool> myselfPeerChange = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    myselfPeerController.addListener(_updateMyselfPeer);
    init();
  }

  _updateMyselfPeer() {
    myselfPeerChange.value = !myselfPeerChange.value;
  }

  init() async {
    bool isAuth = widget.credential != null;
    final List<PlatformDataField> p2pLoginInputFieldDef = [];
    p2pLoginInputFieldDef.add(PlatformDataField(
      name: 'credential',
      label: 'Credential(Mobile/Email/Name)',
      readOnly: isAuth,
      cancel: !isAuth,
      prefixIcon: !isAuth
          ? TextButton.icon(
              icon: const Icon(Icons.person, color: Colors.yellowAccent),
              onPressed: () async {
                await DialogUtil.show(
                    context: context, builder: _buildMyselfPeers);
                var myselfPeer = myselfPeerController.current;
                if (myselfPeer != null) {
                  String? credential = myselfPeer.loginName;
                  if (StringUtil.isNotEmpty(credential)) {
                    controller.setValue('credential', credential);
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
    p2pLoginInputFieldDef.add(PlatformDataField(
      name: 'password',
      label: 'Password',
      inputType: InputType.password,
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      ),
    ));
    controller = FormInputController(p2pLoginInputFieldDef);
    String? credential = controller.getValue('credential');
    if (credential == null) {
      credential = widget.credential;
      String? lastCredentialName = await myselfPeerService.lastCredentialName();
      if (lastCredentialName != null) {
        MyselfPeer? myselfPeer =
            await myselfPeerService.findOneByLogin(lastCredentialName);
        if (myselfPeer != null) {
          credential ??= lastCredentialName;
          if (StringUtil.isNotEmpty(credential)) {
            controller.setValue('credential', credential);
          }
          return;
        }
      }
    }
  }

  List<TileData> _buildMyselfPeerTiles() {
    List<TileData> tiles = [];
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
    if (myselfPeers.isNotEmpty) {
      int index = 0;
      for (var myselfPeer in myselfPeers) {
        int i = index;
        var tile = TileData(
          title: myselfPeer.loginName,
          subtitle: myselfPeer.peerId,
          titleTail: myselfPeer.name,
          prefix: myselfPeer.avatarImage,
          suffix: IconButton(
            onPressed: () async {
              bool? confirm = await DialogUtil.confirm(context,
                  content: 'Do you want delete peer');
              if (confirm == null || confirm == false) {
                return;
              }
              chatMessageService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              messageAttachmentService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              peerProfileService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              chatSummaryService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              linkmanService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              groupService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              groupMemberService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              conferenceService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              peerClientService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              peerEndpointService.delete(
                  where: 'ownerpeerId=?', whereArgs: [myselfPeer.peerId]);
              myselfPeerService
                  .delete(where: 'peerId=?', whereArgs: [myselfPeer.peerId]);
              await myselfPeerController.delete(index: i);
            },
            icon: const Icon(Icons.clear),
          ),
        );
        tiles.add(tile);
        index++;
      }
    }
    return tiles;
  }

  Widget _buildMyselfPeers(BuildContext context) {
    return Dialog(
        child: Column(children: [
      AppBarWidget.buildAppBar(
        context,
        title: CommonAutoSizeText(AppLocalizations.t('Select login peer')),
      ),
      ValueListenableBuilder(
          valueListenable: myselfPeerChange,
          builder:
              (BuildContext context, bool myselfPeerChange, Widget? child) {
            return DataListView(
              tileData: _buildMyselfPeerTiles(),
              currentIndex: myselfPeerController.currentIndex,
              onTap: (int index, String title,
                  {TileData? group, String? subtitle}) {
                myselfPeerController.currentIndex = index;
                Navigator.pop(context);
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
      DialogUtil.error(context, content: 'Must have node credential');
      return;
    }
    if (password == null) {
      DialogUtil.error(context, content: 'Must have node password');
      return;
    }
    try {
      DialogUtil.loadingShow(context);
      String? loginStatus = await myselfPeerService.auth(credential, password);
      if (mounted) {
        DialogUtil.loadingHide(context);
      }
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(loginStatus);
      }
    } catch (e) {
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(e.toString());
      } else {
        DialogUtil.error(context, content: e.toString());
      }
    }
  }

  ///登录
  _login(Map<String, dynamic> values) async {
    String? credential = values[credentialName];
    String? password = values[passwordName];
    if (credential == null) {
      DialogUtil.error(context, content: 'Must have node credential');
      return;
    }
    if (password == null) {
      DialogUtil.error(context, content: 'Must have node password');
      return;
    }
    try {
      DialogUtil.loadingShow(context);
      String? loginStatus = await myselfPeerService.login(credential, password);
      if (mounted) {
        DialogUtil.loadingHide(context);
      }

      if (loginStatus == null) {
        ///连接篇p2p的节点，把自己的信息注册上去
        myselfPeerService.connect();
        if (myself.autoLogin) {
          myselfPeerService.saveAutoCredential(credential, password);
        }

        if (mounted) {
          Application.router
              .navigateTo(context, Application.index, replace: true);
        }
      } else {
        if (mounted) {
          DialogUtil.error(context, content: AppLocalizations.t(loginStatus));
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtil.error(context, content: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      SizedBox(
        height: appDataProvider.portraitSize.height * 0.1,
      ),
      ImageUtil.buildImageWidget(
        image: 'assets/images/colla.png',
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
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: FormInputWidget(
            mainAxisAlignment: MainAxisAlignment.start,
            height: appDataProvider.portraitSize.height * 0.3,
            spacing: 10.0,
            onOk: (Map<String, dynamic> values) async {
              if (widget.credential == null) {
                await _login(values);
              } else {
                await _auth(values);
              }
            },
            okLabel: widget.credential == null ? 'Login' : 'Auth',
            controller: controller,
          ))
    ]);
  }
}
