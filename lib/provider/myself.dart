import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

/// 单例本节点对象，包含公私钥，本节点配置，密码和过往的节点信息
/// 在登录成功后被初始化
/// 可以随时获取本节点的信息
class Myself with ChangeNotifier {
  int? id;
  String? peerId;
  String? name;
  String? clientId;

  // peer是ed25519,英语身份认证
  SimplePublicKey? peerPublicKey;
  SimpleKeyPair? peerPrivateKey;

  /// x25519，用于加解密
  SimplePublicKey? publicKey;
  SimpleKeyPair? privateKey;

  MyselfPeer myselfPeer = MyselfPeer('', '', '', '');
  PeerProfile peerProfile = PeerProfile('', '');

  ///当连接p2p节点成功后设置
  PeerClient? myselfPeerClient;
  String? password;
  List<SimpleKeyPair> expiredKeys = [];

  /// signal协议
  String? signalPublicKey;
  String? signalPrivateKey;

  ThemeData _themeData = ThemeData();
  ThemeData _darkThemeData = ThemeData();

  Myself() {
    _buildThemeData();
    _buildDarkThemeData();
  }

  String get myPath {
    return p.join(platformParams.path, name ?? '');
  }

  Widget? get avatarImage {
    return myselfPeer.avatarImage;
  }

  Widget? get avatarIcon {
    return myselfPeer.avatarIcon;
  }

  /// locale操作
  Locale get locale {
    return LocaleUtil.getLocale(peerProfile.locale);
  }

  set locale(Locale locale) {
    if (peerProfile.locale != locale.toString()) {
      peerProfile.locale = locale.toString();
      if (peerProfile.id != null) {
        peerProfileService.update({'locale': peerProfile.locale},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
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

  ThemeData get darkThemeData {
    return _darkThemeData;
  }

  _buildThemeData() {
    ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: Color(peerProfile.seedColor), brightness: Brightness.light);
    TextTheme textTheme;
    if (StringUtil.isNotEmpty(peerProfile.fontFamily)) {
      textTheme = GoogleFonts.getTextTheme(peerProfile.fontFamily!);
    } else {
      textTheme = const TextTheme();
    }

    IconThemeData iconTheme = IconThemeData(color: colorScheme.primary);

    _themeData = ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      iconTheme: iconTheme,
      brightness: Brightness.light,
    );
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

  _buildDarkThemeData() {
    ColorScheme darkColorScheme = ColorScheme.fromSeed(
        seedColor: Color(peerProfile.seedColor), brightness: Brightness.dark);
    IconThemeData iconTheme = IconThemeData(color: darkColorScheme.primary);
    TextTheme textTheme;
    if (StringUtil.isNotEmpty(peerProfile.fontFamily)) {
      textTheme = GoogleFonts.getTextTheme(peerProfile.fontFamily!);
    } else {
      textTheme = const TextTheme();
    }
    _darkThemeData = ThemeData(
      colorScheme: darkColorScheme,
      textTheme: textTheme,
      iconTheme: iconTheme,
      brightness: Brightness.dark,
    );
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

  Color get seedColor {
    return Color(peerProfile.seedColor);
  }

  set seedColor(Color color) {
    if (peerProfile.seedColor != color.value) {
      peerProfile.seedColor = color.value;
      if (peerProfile.id != null) {
        peerProfileService.update({'seedColor': peerProfile.seedColor},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
      _buildThemeData();
      notifyListeners();
    }
  }

  Color get darkSeedColor {
    return Color(peerProfile.seedColor);
  }

  set darkSeedColor(Color color) {
    if (peerProfile.darkSeedColor != color.value) {
      peerProfile.darkSeedColor = color.value;
      if (peerProfile.id != null) {
        peerProfileService.update({'darkSeedColor': peerProfile.darkSeedColor},
            where: 'id=?', whereArgs: [peerProfile.id!]);
      }
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
final myself = Myself();
