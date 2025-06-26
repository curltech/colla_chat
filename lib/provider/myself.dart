import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// 单例本节点对象，包含公私钥，本节点配置，密码和过往的节点信息
/// 在登录成功后被初始化
/// 可以随时获取本节点的信息
class Myself with ChangeNotifier {
  Key key = UniqueKey();
  int? id;
  String? peerId;
  String? name;
  String? clientId;
  Locale _locale = platformParams.locale;

  // peer是ed25519,英语身份认证
  SimplePublicKey? peerPublicKey;
  SimpleKeyPair? peerPrivateKey;

  /// x25519，用于加解密
  SimplePublicKey? publicKey;
  SimpleKeyPair? privateKey;

  MyselfPeer myselfPeer = MyselfPeer('', '', '', '');

  ///当连接p2p节点成功后设置
  PeerClient? myselfPeerClient;
  String? password;
  List<SimpleKeyPair> expiredKeys = [];

  /// signal协议
  String? signalPublicKey;
  String? signalPrivateKey;

  late ColorScheme colorScheme;

  late ColorScheme darkColorScheme;

  late ThemeData _themeData;

  late ThemeData _darkThemeData;

  PlatformStyle platformStyle = PlatformStyle.glass;

  Myself() {
    _buildThemeData();
    _buildDarkThemeData();
    _locale = platformParams.locale;
  }

  PeerProfile get peerProfile {
    PeerProfile? peerProfile = myselfPeer.peerProfile;
    if (peerProfile == null) {
      peerProfile =
          PeerProfile(myselfPeer.peerId, clientId: myselfPeer.clientId);
      peerProfileService.insert(peerProfile);
      myselfPeer.peerProfile = peerProfile;
    }

    return peerProfile;
  }

  set peerProfile(PeerProfile peerProfile) {
    if (myselfPeer.peerProfile != peerProfile) {
      myselfPeer.peerProfile = peerProfile;
      notifyListeners();
    }
  }

  _buildThemeData() {
    TextTheme textTheme = const TextTheme();
    colorScheme = SeedColorScheme.fromSeeds(
      brightness: Brightness.light,
      primaryKey: primaryColor,
      primary: primaryColor,
      secondaryKey: secondaryColor,
      secondary: secondaryColor,
      neutralKey: primaryColor,
      tertiaryKey: primaryColor,
      tones: FlexTones.vivid(Brightness.light),
    );
    _themeData = ThemeData.from(
        colorScheme: colorScheme, textTheme: textTheme, useMaterial3: true);
  }

  _buildDarkThemeData() {
    TextTheme textTheme = const TextTheme();
    darkColorScheme = SeedColorScheme.fromSeeds(
      brightness: Brightness.dark,
      primaryKey: primaryColor,
      primary: primaryColor,
      secondaryKey: secondaryColor,
      secondary: secondaryColor,
      neutralKey: primaryColor,
      tertiaryKey: primaryColor,
      tones: FlexTones.vivid(Brightness.dark),
    );
    _darkThemeData = ThemeData.from(
      colorScheme: darkColorScheme,
      textTheme: textTheme,
      useMaterial3: true,
    );
  }

  Color get primaryColor {
    return Color(peerProfile.primaryColor);
  }

  Color get secondaryColor {
    return Color(peerProfile.secondaryColor);
  }

  set primaryColor(Color color) {
    if (peerProfile.primaryColor != color.toARGB32()) {
      peerProfile.primaryColor = color.toARGB32();
      if (peerProfile.id != null) {
        peerProfileService.update({'primaryColor': peerProfile.primaryColor},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
      _buildThemeData();
      _buildDarkThemeData();
      notifyListeners();
    }
  }

  set secondaryColor(Color color) {
    if (peerProfile.secondaryColor != color.toARGB32()) {
      peerProfile.secondaryColor = color.toARGB32();
      if (peerProfile.id != null) {
        peerProfileService.update(
            {'secondaryColor': peerProfile.secondaryColor},
            where: 'id=?',
            whereArgs: [peerProfile.id!]);
      }
      _buildThemeData();
      _buildDarkThemeData();
      notifyListeners();
    }
  }

  String? get fontFamily {
    return peerProfile.fontFamily;
  }

  set fontFamily(String? fontFamily) {
    if (peerProfile.fontFamily != fontFamily) {
      peerProfile.fontFamily = fontFamily;
      if (peerProfile.id != null) {
        peerProfileService.update({'fontFamily': peerProfile.fontFamily},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
      _buildThemeData();
      _buildDarkThemeData();
      notifyListeners();
    }
  }

  ThemeData get themeData {
    if (themeMode == ThemeMode.light) {
      return _themeData;
    } else if (themeMode == ThemeMode.dark) {
      return _darkThemeData;
    } else {
      return _themeData;
    }
  }

  setThemeData({ThemeData? themeData, ThemeData? darkThemeData}) {
    bool updated = false;
    if (themeData != null && themeData != _themeData) {
      _themeData = themeData;
      updated = true;
    }
    if (darkThemeData != null && darkThemeData != _darkThemeData) {
      _darkThemeData = darkThemeData;
      updated = true;
    }
    if (updated) {
      notifyListeners();
    }
  }

  ThemeData get darkThemeData {
    return _darkThemeData;
  }

  Color get primary {
    if (themeMode == ThemeMode.light) {
      return _themeData.colorScheme.primary;
    } else if (themeMode == ThemeMode.dark) {
      return _darkThemeData.colorScheme.primary;
    } else {
      return _themeData.colorScheme.primary;
    }
  }

  Color get secondary {
    if (themeMode == ThemeMode.light) {
      return _themeData.colorScheme.secondary;
    } else if (themeMode == ThemeMode.dark) {
      return _darkThemeData.colorScheme.secondary;
    } else {
      return _themeData.colorScheme.secondary;
    }
  }

  ThemeMode get themeMode {
    ThemeMode themeMode = ThemeMode.values
        .firstWhere((element) => element.name == peerProfile.themeMode);
    return themeMode;
  }

  set themeMode(ThemeMode themeMode) {
    if (peerProfile.themeMode != themeMode.name) {
      peerProfile.themeMode = themeMode.name;
      if (peerProfile.id != null) {
        peerProfileService.update({'themeMode': peerProfile.themeMode},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
      notifyListeners();
    }
  }

  Brightness getBrightness(BuildContext context) {
    if (themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context);
    } else {
      if (themeMode == ThemeMode.light) {
        return Brightness.light;
      } else {
        return Brightness.dark;
      }
    }
  }

  Color getBackgroundColor(BuildContext context) {
    Brightness brightness = getBrightness(context);
    if (brightness == Brightness.light) {
      return Colors.white;
    }
    return Colors.black;
  }

  String get myPath {
    return p.join(platformParams.path, name ?? '');
  }

  Widget? get avatarImage {
    return myselfPeer.avatarImage ?? AppImage.mdAppImage;
  }

  Widget? get avatarIcon {
    return myselfPeer.avatarIcon ?? AppIcon.mdAppIcon;
  }

  /// locale操作
  Locale get profileLocale {
    return LocaleUtil.getLocale(peerProfile.locale);
  }

  set profileLocale(Locale locale) {
    if (peerProfile.locale != locale.toString()) {
      peerProfile.locale = locale.toString();
      if (peerProfile.id != null) {
        peerProfileService.update({'locale': peerProfile.locale},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
    }
  }

  /// locale操作
  Locale get locale {
    return _locale;
  }

  set locale(Locale locale) {
    if (locale != _locale) {
      _locale = locale;
      myself.profileLocale = _locale;
      notifyListeners();
    }
  }

  bool get autoLogin {
    return peerProfile.autoLogin;
  }

  set autoLogin(bool autoLogin) {
    if (peerProfile.autoLogin != autoLogin) {
      peerProfile.autoLogin = autoLogin;
      if (peerProfile.id != null) {
        peerProfileService.update({'autoLogin': peerProfile.autoLogin},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
      notifyListeners();
    }
  }
}

///全集唯一的当前用户，存放在内存中，当前重新登录时里面的值会钱换到新的值
final Myself myself = Myself();
