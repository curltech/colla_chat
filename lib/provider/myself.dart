import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/tool/string_util.dart';
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
  Key key = UniqueKey();
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

  PeerProfile get peerProfile {
    PeerProfile? peerProfile = myselfPeer.peerProfile;
    peerProfile = peerProfile ??
        PeerProfile(myselfPeer.peerId, clientId: myselfPeer.clientId);
    myselfPeer.peerProfile = peerProfile;

    return peerProfile;
  }

  set peerProfile(PeerProfile peerProfile) {
    myselfPeer.peerProfile = peerProfile;
    notifyListeners();
  }

  _buildThemeData() {
    FlexScheme? scheme;
    if (peerProfile.scheme != null) {
      scheme =
          StringUtil.enumFromString(FlexScheme.values, peerProfile.scheme!);
    }

    if (scheme != null) {
      _themeData = FlexThemeData.light(
        scheme: scheme,
      );
      return;
    }
    TextTheme textTheme = const TextTheme();
    // final ColorScheme colorScheme = SeedColorScheme.fromSeeds(
    //   brightness: Brightness.light,
    //   primaryKey: primaryColor,
    //   secondaryKey: secondaryColor,
    //   neutralKey: primaryColor,
    //   tertiaryKey: primaryColor,
    //   tones: FlexTones.vivid(Brightness.light),
    // );
    // _themeData = ThemeData.from(
    //   colorScheme: colorScheme,
    //   textTheme: textTheme,
    //   useMaterial3: true,
    // );
    FlexSchemeColor lightColor = FlexSchemeColor.from(
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
    );
    _themeData = FlexThemeData.light(
      colors: scheme == null ? lightColor : null,
      scheme: scheme,
      swapColors: true,
      usedColors: 6,
      lightIsWhite: false,
      subThemesData: FlexSubThemesData(
        defaultRadius: 8,
        inputDecoratorRadius: 2,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorIsFilled: false,
        inputDecoratorFillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
        inputDecoratorBorderType: FlexInputBorderType.underline,
        inputDecoratorUnfocusedHasBorder: false,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorBorderWidth: 0,
        inputDecoratorFocusedBorderWidth: 0,
      ),
      appBarStyle: FlexAppBarStyle.primary,
      appBarOpacity: 1,
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
    FlexScheme? darkScheme;
    if (peerProfile.darkScheme != null) {
      darkScheme =
          StringUtil.enumFromString(FlexScheme.values, peerProfile.darkScheme!);
    }
    if (darkScheme != null) {
      _themeData = FlexThemeData.dark(
        scheme: darkScheme,
      );
      return;
    }
    TextTheme textTheme = const TextTheme();
    // final ColorScheme colorScheme = SeedColorScheme.fromSeeds(
    //   brightness: Brightness.dark,
    //   primaryKey: primaryColor,
    //   secondaryKey: secondaryColor,
    //   neutralKey: primaryColor,
    //   tertiaryKey: primaryColor,
    //   tones: FlexTones.vivid(Brightness.dark),
    // );
    // _darkThemeData = ThemeData.from(
    //   colorScheme: colorScheme,
    //   textTheme: textTheme,
    //   useMaterial3: true,
    // );
    FlexSchemeColor darkColor = FlexSchemeColor.from(
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.dark,
    );
    _darkThemeData = FlexThemeData.dark(
      colors: darkScheme == null ? darkColor : null,
      scheme: darkScheme,
      swapColors: true,
      usedColors: 6,
      darkIsTrueBlack: false,
      subThemesData: FlexSubThemesData(
        defaultRadius: 8,
        inputDecoratorRadius: 2,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorIsFilled: false,
        inputDecoratorFillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
        inputDecoratorBorderType: FlexInputBorderType.underline,
        inputDecoratorUnfocusedHasBorder: false,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorBorderWidth: 0,
        inputDecoratorFocusedBorderWidth: 0,
      ),
      appBarStyle: FlexAppBarStyle.background,
      appBarOpacity: 1,
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

  Color get primaryColor {
    return Color(peerProfile.primaryColor);
  }

  Color get secondaryColor {
    return Color(peerProfile.secondaryColor);
  }

  set primaryColor(Color color) {
    if (peerProfile.primaryColor != color.value) {
      peerProfile.primaryColor = color.value;
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
    if (peerProfile.secondaryColor != color.value) {
      peerProfile.secondaryColor = color.value;
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
  Locale get locale {
    if (peerProfile.id != null) {
      return LocaleUtil.getLocale(peerProfile.locale);
    } else if (platformParams.locale != null) {
      return platformParams.locale!;
    } else {
      return LocaleUtil.getLocale(peerProfile.locale);
    }
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
