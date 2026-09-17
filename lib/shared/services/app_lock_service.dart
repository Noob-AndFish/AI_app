// 日记隐私锁服务
// 每篇日记独立密码（flutter_secure_storage，按 entryId 存储）+ 生物识别（local_auth）
// "忘记密码"= 清空该篇密码 + 标记 is_locked=0（降级处理）

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  static const String _pinKeyPrefix = 'journal_pin_';
  static const int _pinLength = 6;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _key(int entryId) => '$_pinKeyPrefix$entryId';

  /// 该篇日记是否已设置密码
  Future<bool> isPinSetFor(int entryId) async {
    final pin = await _storage.read(key: _key(entryId));
    return pin != null && pin.length == _pinLength;
  }

  /// 设置该篇日记密码（覆盖旧密码）
  Future<void> setPinFor(int entryId, String pin) async {
    if (pin.length != _pinLength) {
      throw ArgumentError('密码必须是 $_pinLength 位');
    }
    await _storage.write(key: _key(entryId), value: pin);
  }

  /// 验证该篇日记密码
  Future<bool> verifyPinFor(int entryId, String pin) async {
    final stored = await _storage.read(key: _key(entryId));
    if (stored == null) return false;
    return stored == pin;
  }

  /// 清空该篇日记密码（不修改 is_locked 字段，由调用方处理）
  Future<void> resetPinFor(int entryId) async {
    await _storage.delete(key: _key(entryId));
  }

  /// 是否支持生物识别
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// 生物识别（设备级，作为 verify 模式的便捷入口）
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: '请验证身份以查看加锁日记',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
