import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureSessionStorageProvider = Provider<SecureSessionStorage>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return const SecureSessionStorage(storage);
});

class StoredSessionData {
  const StoredSessionData({
    required this.cookieHeader,
    required this.phone,
    required this.password,
    required this.displayName,
    required this.roleName,
    required this.adminId,
  });

  final String cookieHeader;
  final String phone;
  final String password;
  final String displayName;
  final String roleName;
  final String adminId;
}

class SecureSessionStorage {
  const SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _keyCookie = 'hkjobs_session_cookie';
  static const String _keyPhone = 'hkjobs_phone';
  static const String _keyPassword = 'hkjobs_password';
  static const String _keyDisplayName = 'hkjobs_display_name';
  static const String _keyRoleName = 'hkjobs_role_name';
  static const String _keyAdminId = 'hkjobs_admin_id';

  Future<void> saveSession(StoredSessionData data) async {
    await Future.wait([
      _storage.write(key: _keyCookie, value: data.cookieHeader),
      _storage.write(key: _keyPhone, value: data.phone),
      _storage.write(key: _keyPassword, value: data.password),
      _storage.write(key: _keyDisplayName, value: data.displayName),
      _storage.write(key: _keyRoleName, value: data.roleName),
      _storage.write(key: _keyAdminId, value: data.adminId),
    ]);
  }

  Future<void> updateCookie(String cookieHeader) async {
    await _storage.write(key: _keyCookie, value: cookieHeader);
  }

  Future<StoredSessionData?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _keyCookie),
      _storage.read(key: _keyPhone),
      _storage.read(key: _keyPassword),
      _storage.read(key: _keyDisplayName),
      _storage.read(key: _keyRoleName),
      _storage.read(key: _keyAdminId),
    ]);

    final cookie = values[0];
    final phone = values[1];
    final password = values[2];
    if (cookie == null ||
        cookie.isEmpty ||
        phone == null ||
        phone.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return StoredSessionData(
      cookieHeader: cookie,
      phone: phone,
      password: password,
      displayName: values[3] ?? 'ADMIN HK',
      roleName: values[4] ?? 'Admin',
      adminId: values[5] ?? '52',
    );
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyCookie),
      _storage.delete(key: _keyPhone),
      _storage.delete(key: _keyPassword),
      _storage.delete(key: _keyDisplayName),
      _storage.delete(key: _keyRoleName),
      _storage.delete(key: _keyAdminId),
    ]);
  }
}
