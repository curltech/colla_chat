import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

///在操作系统层面的安全存储
class LocalSecurityStorage {
  final IOSOptions iOptions =
      const IOSOptions(accessibility: KeychainAccessibility.unlocked);
  final AndroidOptions aOptions =
      const AndroidOptions(encryptedSharedPreferences: true);
  final MacOsOptions mOptions = const MacOsOptions(synchronizable: true);
  final WindowsOptions wOptions =
      const WindowsOptions(useBackwardCompatibility: true);
  final LinuxOptions lOptions = const LinuxOptions();
  late final FlutterSecureStorage _secureStorage;

  LocalSecurityStorage() {
    _secureStorage = FlutterSecureStorage(
      iOptions: iOptions,
      aOptions: aOptions,
      wOptions: wOptions,
      mOptions: mOptions,
      lOptions: lOptions,
    );
  }

  String _getKey(String key, {bool userKey = true}) {
    if (userKey) {
      String? peerId = myself.peerId;
      if (peerId == null) {
        return key;
      }

      return '$peerId-$key';
    }
    return key;
  }

  save(String key, String value, {bool userKey = true}) async {
    try {
      await _secureStorage.write(
        key: _getKey(key, userKey: userKey),
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
      String? v = await get(key, userKey: userKey);
      if (v == null) {
        throw 'save value failure, value is null';
      }
      if (v != value) {
        throw 'save value failure, value is not equal';
      }
    } catch (e) {
      logger.e('LocalSecurityStorage save:$e');
    }
  }

  Future<Map<String, String>> getAll() async {
    try {
      return await _secureStorage.readAll(
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
    } catch (e) {
      logger.e('LocalSecurityStorage getAll:$e');
    }
    return {};
  }

  Future<String?> get(String key, {bool userKey = true}) async {
    try {
      Map<String, String> values = await _secureStorage.readAll(
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
      return values[_getKey(key, userKey: userKey)];
    } catch (e) {
      logger.e('LocalSecurityStorage get:$e');
    }
    return null;
  }

  remove(String key, {bool userKey = true}) async {
    try {
      return await _secureStorage.delete(
        key: _getKey(key, userKey: userKey),
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
    } catch (e) {
      logger.e('LocalSecurityStorage remove:$e');
    }
  }

  removeAll() async {
    try {
      return await _secureStorage.deleteAll(
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
    } catch (e) {
      logger.e('LocalSecurityStorage removeAll:$e');
    }
  }
}

final LocalSecurityStorage localSecurityStorage = LocalSecurityStorage();

class LocalSharedPreferences {
  late final SharedPreferences prefs;

  init() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<String?> _encrypt(String value) async {
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = false;
    securityContext.needEncrypt = true;
    securityContext.needSign = false;
    try {
      List<int> raw = CryptoUtil.stringToUtf8(value);
      securityContext.payload = raw;
      var result = await linkmanCryptographySecurityContextService
          .encrypt(securityContext);
      if (!result) {
        logger.e('linkmanCryptographySecurityContextService encrypt failure');
      }
      List<int> data = securityContext.payload;

      return CryptoUtil.encodeBase64(data);
    } catch (err) {
      logger.e('SecurityContextService encrypt err:$err');
    }

    return null;
  }

  Future<String?> _decrypt(String value) async {
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = false;
    securityContext.needEncrypt = true;
    securityContext.needSign = false;
    try {
      List<int> data = CryptoUtil.decodeBase64(value);
      securityContext.payload = data;
      var result = await linkmanCryptographySecurityContextService
          .decrypt(securityContext);
      if (!result) {
        logger.e('linkmanCryptographySecurityContextService decrypt failure');
      }
      data = securityContext.payload;
      return CryptoUtil.utf8ToString(data);
    } catch (e) {
      logger.e('SecurityContextService decrypt err:$e');
    }
    return null;
  }

  String _getKey(String key, {bool userKey = true}) {
    if (userKey) {
      String? peerId = myself.peerId;
      peerId = peerId ?? '';

      return '$peerId-$key';
    }
    return key;
  }

  save(String key, String value,
      {bool encrypt = false, bool userKey = true}) async {
    try {
      if (encrypt) {
        String? encrypted = await _encrypt(value);
        if (encrypted != null) {
          return await prefs.setString(
              _getKey(key, userKey: userKey), encrypted);
        }
      } else {
        return await prefs.setString(_getKey(key, userKey: userKey), value);
      }
    } catch (e) {
      logger.e('LocalSharedPreferences save:$e');
    }
  }

  Future<String?> get(String key,
      {bool encrypt = false, bool userKey = true}) async {
    try {
      String? value = prefs.getString(_getKey(key, userKey: userKey));
      if (encrypt && value != null) {
        String? decrypted = await _decrypt(value);
        if (decrypted != null) {
          return decrypted;
        }
      }
      return value;
    } catch (e) {
      logger.e('LocalSharedPreferences get:$e');
    }
    return null;
  }

  remove(String key, {bool userKey = true}) async {
    try {
      return await prefs.remove(_getKey(key, userKey: userKey));
    } catch (e) {
      logger.e('LocalSharedPreferences remove:$e');
    }
  }
}

final LocalSharedPreferences localSharedPreferences = LocalSharedPreferences();
