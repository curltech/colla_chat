import 'package:colla_chat/platform.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'logger.dart';

///在操作系统层面的安全存储
class LocalSecurityStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  save(String key, String value) async {
    try {
      const iOptions =
          IOSOptions(accessibility: KeychainAccessibility.unlocked);
      AndroidOptions aOptions = const AndroidOptions(
        encryptedSharedPreferences: true,
      );
      if (platformParams.android) {
        return await _secureStorage.write(
            key: key, value: value, aOptions: aOptions);
      } else if (platformParams.ios) {
        return await _secureStorage.write(
            key: key, value: value, iOptions: iOptions);
      } else {
        return await _secureStorage.write(key: key, value: value);
      }
    } catch (e) {
      logger.e('LocalSecurityStorage save:$e');
    }
  }

  Future<Map<String, String>> getAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      logger.e('LocalSecurityStorage getAll:$e');
    }
    return {};
  }

  Future<String?> get(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      logger.e('LocalSecurityStorage get:$e');
    }
    return null;
  }

  remove(String key) async {
    try {
      return await _secureStorage.delete(key: key);
    } catch (e) {
      logger.e('LocalSecurityStorage remove:$e');
    }
  }

  removeAll() async {
    try {
      return await _secureStorage.deleteAll();
    } catch (e) {
      logger.e('LocalSecurityStorage removeAll:$e');
    }
  }
}

final LocalSecurityStorage localSecurityStorage = LocalSecurityStorage();
