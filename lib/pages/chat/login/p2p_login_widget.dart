import 'dart:core';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/myself_peer_view_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

/// 远程登录组件，一个card下的录入框和按钮组合
class P2pLoginWidget extends StatefulWidget {
  final void Function(bool result)? onAuthenticate;

  const P2pLoginWidget({Key? key, this.onAuthenticate}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginWidgetState();
}

class _P2pLoginWidgetState extends State<P2pLoginWidget> {
  late final FormInputController controller;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() {
    final List<ColumnFieldDef> p2pLoginInputFieldDef = [];
    p2pLoginInputFieldDef.add(ColumnFieldDef(
      name: 'credential',
      label: 'Credential(Mobile/Email/LoginName)',
      prefixIcon: IconButton(
        icon: Icon(Icons.person, color: myself.primary),
        onPressed: () async {
          await DialogUtil.show(context: context, builder: _buildMyselfPeers);
          var myselfPeer = myselfPeerController.current;
          if (myselfPeer != null) {
            String? credential = myselfPeer.loginName;
            if (StringUtil.isNotEmpty(credential)) {
              ColumnFieldController? columnFieldController =
                  controller.controllers['credential'];
              if (columnFieldController != null) {
                columnFieldController.value = credential;
              }
            }
          }
        },
      ),
      cancel: true,
    ));
    p2pLoginInputFieldDef.add(ColumnFieldDef(
      name: 'password',
      label: 'Password',
      inputType: InputType.password,
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      ),
    ));

    controller = FormInputController(p2pLoginInputFieldDef);
  }

  Widget _buildMyselfPeers(BuildContext context) {
    return Dialog(
        child: Column(children: [
      AppBarWidget.buildAppBar(
        context,
        title: CommonAutoSizeText(AppLocalizations.t('Select login peer')),
      ),
      const MyselfPeerViewWidget()
    ]));
  }

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
      bool loginStatus = await myselfPeerService.login(credential, password);
      if (mounted) {
        DialogUtil.loadingHide(context);
      }
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(loginStatus);
      } else {
        if (loginStatus) {
          if (myself.autoLogin) {
            myselfPeerService.saveAutoCredential(credential, password);
          }

          if (mounted) {
            Application.router
                .navigateTo(context, Application.index, replace: true);
          }
        } else {
          if (mounted) {
            DialogUtil.error(context,
                content: AppLocalizations.t('Login fail'));
          }
        }
      }
    } catch (e) {
      if (widget.onAuthenticate != null) {
        widget.onAuthenticate!(false);
      } else {
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
      SizedBox(
        height: appDataProvider.portraitSize.height * 0.1,
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: FutureBuilder(
          future: myselfPeerService.lastCredentialName(),
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            if (!snapshot.hasData) {
              return LoadingUtil.buildLoadingIndicator();
            }
            String? credential = snapshot.data;
            if (StringUtil.isNotEmpty(credential)) {
              controller.setInitValue({'credential': credential});
            }
            return FormInputWidget(
              mainAxisAlignment: MainAxisAlignment.start,
              height: appDataProvider.portraitSize.height * 0.3,
              spacing: 10.0,
              onOk: (Map<String, dynamic> values) async {
                await _login(values);
              },
              okLabel: 'Login',
              controller: controller,
            );
          },
        ),
      ),
    ]);
  }
}
