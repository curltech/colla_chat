import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger.dart';

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

  String _getKey(String key) {
    String? peerId = myself.peerId;
    peerId = peerId ?? '';

    return '$peerId-key';
  }

  save(String key, String value) async {
    try {
      return await _secureStorage.write(
        key: key,
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
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

  Future<String?> get(String key) async {
    try {
      return await _secureStorage.read(
        key: _getKey(key),
        iOptions: iOptions,
        aOptions: aOptions,
        wOptions: wOptions,
        mOptions: mOptions,
        lOptions: lOptions,
      );
    } catch (e) {
      logger.e('LocalSecurityStorage get:$e');
    }
    return null;
  }

  remove(String key) async {
    try {
      return await _secureStorage.delete(
        key: _getKey(key),
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

  String _getKey(String key) {
    String? peerId = myself.peerId;
    peerId = peerId ?? '';

    return '$peerId-key';
  }

  save(String key, String value, {bool encrypt = false}) async {
    try {
      if (encrypt) {
        String? encrypted = await _encrypt(value);
        if (encrypted != null) {
          return await prefs.setString(_getKey(key), encrypted);
        }
      } else {
        return await prefs.setString(_getKey(key), value);
      }
    } catch (e) {
      logger.e('LocalSharedPreferences save:$e');
    }
  }

  Future<String?> get(String key, {bool encrypt = false}) async {
    try {
      String? value = prefs.getString(_getKey(key));
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

  remove(String key) async {
    try {
      return await prefs.remove(_getKey(key));
    } catch (e) {
      logger.e('LocalSharedPreferences remove:$e');
    }
  }
}

final LocalSharedPreferences localSharedPreferences = LocalSharedPreferences();
