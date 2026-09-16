// 日记隐私锁服务
// 管理 4 位数字密码（flutter_secure_storage）+ 生物识别（local_auth）
// 重置密码 = 清空密码 + 解锁所有日记（降级处理）

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/repositories/journal_repository.dart';

class AppLockService {
  static const String _pinKey = 'app_lock_pin';
  static const int _pinLength = 6;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final JournalRepository _journalRepo = JournalRepository();

  /// 是否已设置密码
  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.length == _pinLength;
  }

  /// 设置密码（覆盖旧密码）
  Future<void> setPin(String pin) async {
    if (pin.length != _pinLength) {
      throw ArgumentError('密码必须是 $_pinLength 位');
    }
    await _storage.write(key: _pinKey, value: pin);
  }

  /// 验证密码
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == pin;
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

  /// 生物识别
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

  /// 重置密码：清空密码 + 解锁所有日记
  /// 用于"忘记密码"降级处理
  Future<void> resetPin() async {
    await _storage.delete(key: _pinKey);
    final all = await _journalRepo.getAll();
    for (final e in all) {
      if (e.locked) {
        await _journalRepo.toggleLocked(e.id!, true);
      }
    }
  }
}
