import 'package:flutter_secure_storage/flutter_secure_storage.dart';

///在操作系统层面的安全存储
class LocalSecurityStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  save(String key, String value) async {
    return await _secureStorage.write(key: key, value: value);
  }

  Future<Map<String, String>> getAll() async {
    return await _secureStorage.readAll();
  }

  Future<String?> get(String key) async {
    return await _secureStorage.read(key: key);
  }

  remove(String key) async {
    return await _secureStorage.delete(key: key);
  }

  removeAll() async {
    return await _secureStorage.deleteAll();
  }
}

final LocalSecurityStorage localSecurityStorage = LocalSecurityStorage();
