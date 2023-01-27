import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
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

  late ThemeData _themeData;

  late ThemeData _darkThemeData;

  Myself() {
    _buildThemeData();
    _buildDarkThemeData();
  }

  _buildThemeData() {
    FlexSchemeColor lightColor = FlexSchemeColor.from(
      primary: Color(peerProfile.seedColor),
      brightness: Brightness.light,
    );
    TextTheme textTheme = const TextTheme();

    _themeData = FlexThemeData.light(
      colors: lightColor,
      //scheme: FlexScheme.blue,
      swapColors: false,
      usedColors: 6,
      lightIsWhite: false,
      subThemesData: const FlexSubThemesData(defaultRadius: 8),
      appBarStyle: FlexAppBarStyle.primary,
      appBarOpacity: 0.9,
      transparentStatusBar: false,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 2,
      appBarElevation: 0.5,
      //FlexColorScheme.comfortablePlatformDensity
      visualDensity: VisualDensity.standard,
      fontFamily: peerProfile.fontFamily ?? GoogleFonts.notoSans().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      tones: FlexTones.material(Brightness.light),
      typography: Typography.material2021(
        platform: defaultTargetPlatform,
      ),
      keyColors: const FlexKeyColors(),
      useMaterial3ErrorColors: true,
      useMaterial3: true,
    );
  }

  _buildDarkThemeData() {
    FlexSchemeColor darkColor = FlexSchemeColor.from(
      primary: seedColor,
      brightness: Brightness.dark,
    );
    TextTheme textTheme = const TextTheme();

    _darkThemeData = FlexThemeData.dark(
      colors: darkColor,
      //scheme: FlexScheme.blue,
      swapColors: false,
      usedColors: 6,
      darkIsTrueBlack: false,
      subThemesData: const FlexSubThemesData(defaultRadius: 8),
      appBarStyle: FlexAppBarStyle.background,
      appBarOpacity: 0.9,
      transparentStatusBar: false,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 2,
      appBarElevation: 0.5,
      //FlexColorScheme.comfortablePlatformDensity
      visualDensity: VisualDensity.standard,
      fontFamily: peerProfile.fontFamily ?? GoogleFonts.notoSans().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      tones: FlexTones.material(Brightness.dark),
      typography: Typography.material2021(
        platform: defaultTargetPlatform,
      ),
      keyColors: const FlexKeyColors(),
      useMaterial3ErrorColors: true,
      useMaterial3: true,
    );
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
