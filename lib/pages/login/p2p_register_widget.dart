import 'dart:io';
import 'dart:typed_data';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/mobile_util.dart';
import 'package:colla_chat/tool/phone_number_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;
import 'package:regexpattern/regexpattern.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:colla_chat/datastore/sqlite3.dart';

/// 用户注册组件，一个card下的录入框和按钮组合
class P2pRegisterWidget extends StatelessWidget {
  final SwiperController? swiperController;

  P2pRegisterWidget({super.key, this.swiperController}) {
    if (platformParams.mobile) {
      MobileUtil.carrierRegionCode().then((value) {
        countryCode.value = value;
      });
    }
  }

  final ValueNotifier<String> countryCode = ValueNotifier<String>('CN');
  final TextEditingController mobileController = TextEditingController();
  final ValueNotifier<String?> peerId = ValueNotifier<String?>(null);
  final ValueNotifier<Uint8List?> avatar = ValueNotifier<Uint8List?>(null);
  final List<PlatformDataField> p2pRegisterDataFields = [
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(
          Icons.person,
          color: myself.primary,
        )),
    PlatformDataField(
      name: 'loginName',
      label: 'LoginName',
      prefixIcon: Icon(
        Icons.mobile_friendly,
        color: myself.primary,
      ),
    ),
    PlatformDataField(
        name: 'email',
        label: 'Email',
        prefixIcon: Icon(
          Icons.email,
          color: myself.primary,
        ),
        textInputType: TextInputType.emailAddress),
    PlatformDataField(
        name: 'plainPassword',
        label: 'PlainPassword',
        inputType: InputType.password,
        prefixIcon: Icon(
          Icons.password,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'confirmPassword',
        label: 'ConfirmPassword',
        inputType: InputType.password,
        prefixIcon: Icon(
          Icons.confirmation_num,
          color: myself.primary,
        ))
  ];
  late final FormInputController formInputController =
      FormInputController(p2pRegisterDataFields);

  Future<void> _pickAvatar(
    BuildContext context,
    String peerId,
  ) async {
    Uint8List? avatar = await ImageUtil.pickAvatar(context: context);
    if (avatar != null) {
      await myselfPeerService.updateAvatar(peerId, avatar);
      this.avatar.value = avatar;
    }
  }

  Future<File?> _restore(Map<String, dynamic> values) async {
    String? backupFile;
    if (platformParams.desktop) {
      List<XFile>? xfiles = await FileUtil.pickFiles();
      if (xfiles!=null && xfiles.isNotEmpty) {
        backupFile = xfiles[0].path;
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets();
      if (assets != null && assets.isNotEmpty) {
        backupFile = (await assets[0].file)?.path;
      }
    }
    if (backupFile != null) {
      return sqlite3.restore(path: backupFile);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<FormButton>? formButtons = [];
    formButtons.add(FormButton(
        label: 'Register',
        buttonStyle:
            StyleUtil.buildButtonStyle(backgroundColor: myself.primary),
        onTap: _onOk));
    formButtons.add(FormButton(
        label: 'Restore',
        buttonStyle:
            StyleUtil.buildButtonStyle(backgroundColor: myself.primary),
        onTap: _restore));
    return ListView(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: ValueListenableBuilder(
            valueListenable: countryCode,
            builder: (BuildContext context, String countryCode, Widget? child) {
              return IntlPhoneField(
                languageCode: myself.locale.languageCode,
                pickerDialogStyle: PickerDialogStyle(
                    searchFieldInputDecoration: InputDecoration(
                  labelText: AppLocalizations.t('Search country'),
                )),
                invalidNumberMessage:
                    AppLocalizations.t('Invalid Mobile Number'),
                controller: mobileController,
                initialCountryCode: countryCode,
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
                  this.countryCode.value = country.name;
                },
                disableLengthCheck: true,
              );
            },
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
              return nilBox;
            }),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: FormInputWidget(
              height: appDataProvider.portraitSize.height * 0.6,
              spacing: 5.0,
              formButtons: formButtons,
              controller: formInputController,
            )),
      ],
    );
  }

  _onOk(Map<String, dynamic> values) async {
    if (!values.containsKey('name')) {
      DialogUtil.error(content: 'name must be not empty');
      return;
    }
    if (!values.containsKey('loginName')) {
      DialogUtil.error(content: 'loginName must be not empty');
      return;
    }
    String name = values['name'];
    var peer = await myselfPeerService.findOneByName(name);
    if (peer != null) {
      bool? confirm = await DialogUtil.confirm(
          title: 'same name account exist',
          content: 'Do you want to login using exist account?');
      if (confirm == true) {
        swiperController?.move(0);
      }
      return;
    }
    String loginName = values['loginName'];
    peer = await myselfPeerService.findOneByLoginName(loginName);
    if (peer != null) {
      bool? confirm = await DialogUtil.confirm(
          title: 'same loginName account exist',
          content: 'Do you want to login using exist account?');
      if (confirm == true) {
        swiperController?.move(0);
      }
      return;
    }
    if (!values.containsKey('plainPassword')) {
      DialogUtil.error(content: 'plainPassword must be not empty');
      return;
    }
    if (!values.containsKey('confirmPassword')) {
      DialogUtil.error(content: 'confirmPassword must be not empty');
      return;
    }
    String plainPassword = values['plainPassword'];
    String confirmPassword = values['confirmPassword'];
    // 检查密码的难度
    bool isPassword =
        RegVal.hasMatch(plainPassword, RegexPattern.passwordNormal1);
    // isPassword = Validate.isPassword(plainPassword);
    if (!isPassword) {
      DialogUtil.error(content: 'password must be strong password');
      return;
    }
    if (plainPassword != confirmPassword) {
      logger.e('password is not matched');
      DialogUtil.error(content: 'password is not matched');
      return;
    }

    String? email = values['email'];
    try {
      MyselfPeer myselfPeer = await myselfPeerService.register(
          name, loginName, plainPassword,
          mobile: mobileController.text, email: email);
      myself.myselfPeer = myselfPeer;
      myselfPeerController.add(myselfPeer);
      peerId.value = myselfPeer.peerId;
    } catch (e) {
      DialogUtil.error(content: e.toString());
      return;
    }
    DialogUtil.info(
        content:
            '${AppLocalizations.t('Successfully')} ${AppLocalizations.t('create account name')}:$name, ${AppLocalizations.t('loginName')}:$loginName');
    swiperController?.move(0);
  }
}
