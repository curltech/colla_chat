import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/mobile_util.dart';
import 'package:colla_chat/tool/phone_number_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final List<ColumnFieldDef> p2pRegisterInputFieldDef = [
  ColumnFieldDef(
      name: 'name',
      label: 'Name',
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'loginName',
      label: 'LoginName',
      prefixIcon: Icon(
        Icons.mobile_friendly,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'email',
      label: 'Email',
      prefixIcon: Icon(
        Icons.email,
        color: myself.primary,
      ),
      textInputType: TextInputType.emailAddress),
  ColumnFieldDef(
      name: 'plainPassword',
      label: 'PlainPassword',
      inputType: InputType.password,
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'confirmPassword',
      label: 'ConfirmPassword',
      inputType: InputType.password,
      prefixIcon: Icon(
        Icons.confirmation_num,
        color: myself.primary,
      ))
];

/// 用户注册组件，一个card下的录入框和按钮组合
class P2pRegisterWidget extends StatefulWidget {
  const P2pRegisterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pRegisterWidgetState();
}

class _P2pRegisterWidgetState extends State<P2pRegisterWidget> {
  String _countryCode = 'CN';
  TextEditingController mobileController = TextEditingController();
  ValueNotifier<String?> peerId = ValueNotifier<String?>(null);
  ValueNotifier<Uint8List?> avatar = ValueNotifier<Uint8List?>(null);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickAvatar(
    BuildContext context,
    String peerId,
  ) async {
    Uint8List? avatar = await ImageUtil.pickAvatar(context);
    if (avatar != null) {
      await myselfPeerService.updateAvatar(peerId, avatar);
      this.avatar.value = avatar;
    }
  }

  Future<void> _restore() async {
    String? backup;
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles();
      if (xfiles.isNotEmpty) {
        backup = await xfiles[0].readAsString();
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            alignment: Alignment.centerLeft,
            child: ListTile(
              title: CommonAutoSizeText(AppLocalizations.t('Restore peer')),
              leading: Icon(
                Icons.restore,
                color: myself.primary,
              ),
              onTap: () {
                _restore();
              },
            )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: IntlPhoneField(
            controller: mobileController,
            initialCountryCode: _countryCode,
            decoration: InputDecoration(
              labelText: AppLocalizations.t('Mobile'),
              suffixIcon: platformParams.android
                  ? IconButton(
                      onPressed: () async {
                        String? mobile = await MobileUtil.getMobileNumber();
                        if (mobile != null) {
                          int pos = mobile.indexOf('+');
                          if (pos > -1) {
                            mobile = mobile.substring(pos);
                          }
                          phone_numbers_parser.PhoneNumber phoneNumber =
                              PhoneNumberUtil.fromRaw(mobile);
                          mobileController.text = phoneNumber.nsn;
                        }
                      },
                      icon: Icon(
                        Icons.mobile_screen_share,
                        color: myself.primary,
                      ))
                  : null,
            ),
            onChanged: (PhoneNumber phoneNumber) {
              // mobileController.text = phoneNumber.number;
            },
            onCountryChanged: (country) {
              _countryCode = country.name;
            },
            disableLengthCheck: true,
          ),
        ),
        ValueListenableBuilder(
            valueListenable: peerId,
            builder: (BuildContext context, String? peerId, Widget? child) {
              if (peerId != null) {
                Widget avatarImage = ValueListenableBuilder(
                    valueListenable: avatar,
                    builder: (BuildContext context, Uint8List? avatar,
                        Widget? child) {
                      if (avatar != null) {
                        return ImageUtil.buildMemoryImageWidget(avatar);
                      }
                      return AppImage.mdAppImage;
                    });

                return ListTile(
                    title: CommonAutoSizeText(AppLocalizations.t('Avatar')),
                    trailing: avatarImage,
                    onTap: () async {
                      await _pickAvatar(
                        context,
                        peerId,
                      );
                    });
              }
              return Container();
            }),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              height: 380,
              onOk: _onOk,
              okLabel: 'Register',
              columnFieldDefs: p2pRegisterInputFieldDef,
            )),
      ],
    );
  }

  _onOk(Map<String, dynamic> values) {
    String plainPassword = values['plainPassword'];
    String confirmPassword = values['confirmPassword'];
    String name = values['name'];
    String loginName = values['loginName'];
    String email = values['email'];
    if (plainPassword == confirmPassword) {
      myselfPeerService
          .register(name, loginName, plainPassword,
              mobile: mobileController.text, email: email)
          .then((myselfPeer) {
        myself.myselfPeer = myselfPeer;
        myselfPeerController.add(myselfPeer);
        peerId.value = myselfPeer.peerId;
        // Application.router
        //     .navigateTo(context, Application.p2pLogin, replace: true);
      }).onError((error, stackTrace) {
        DialogUtil.error(context, content: error.toString());
      });
    } else {
      logger.e('password is not matched');
    }
  }
}
