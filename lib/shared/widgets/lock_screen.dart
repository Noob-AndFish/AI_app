// 锁屏对话框
// 6 位数字密码输入 + 生物识别按钮 + 忘记密码重置入口
// 每篇日记密码独立，按 entryId 存取
// 模式：setPin（加锁时设置，输入两次确认）/ verify（验证已有密码）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_lock_service.dart';
import '../../features/journal/journal_provider.dart';

enum LockMode { setPin, verify }

class LockScreen extends StatefulWidget {
  final int entryId;
  final String? title;
  final LockMode _mode;

  const LockScreen._({
    required this.entryId,
    this.title,
    required this._mode,
  });

  /// 加锁：立即弹"请设置密码"，输入两次确认
  /// 返回 true 表示用户已完成设置（调用方需自行 toggleLock 标记 is_locked=1）
  static Future<bool> setupForEntry(
    BuildContext context,
    int entryId, {
    String? title,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          LockScreen._(mode: LockMode.setPin, entryId: entryId, title: title),
    );
    return ok ?? false;
  }

  /// 验证：校验该篇日记密码（或生物识别）
  /// 返回 true 表示验证通过（调用方需自行解锁或放行查看）
  static Future<bool> verifyForEntry(
    BuildContext context,
    int entryId, {
    String? title,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          LockScreen._(mode: LockMode.verify, entryId: entryId, title: title),
    );
    return ok ?? false;
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AppLockService _service = AppLockService();

  String _enteredPin = '';
  String? _firstPin; // setPin 模式下第一次输入的密码
  String? _errorText;
  bool _isProcessing = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    if (widget._mode == LockMode.verify) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await _service.isBiometricsAvailable();
    if (mounted) setState(() => _biometricsAvailable = available);
  }

  void _appendDigit(String d) {
    if (_enteredPin.length >= 6 || _isProcessing) return;
    setState(() {
      _enteredPin += d;
      _errorText = null;
    });
    if (_enteredPin.length == 6) {
      _onPinComplete();
    }
  }

  void _backspace() {
    if (_enteredPin.isEmpty || _isProcessing) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _onPinComplete() async {
    setState(() => _isProcessing = true);
    try {
      if (widget._mode == LockMode.setPin) {
        if (_firstPin == null) {
          // 第一次输入，暂存
          _firstPin = _enteredPin;
          setState(() {
            _enteredPin = '';
            _isProcessing = false;
          });
        } else {
          // 第二次输入，比对
          if (_enteredPin == _firstPin) {
            await _service.setPinFor(widget.entryId, _enteredPin);
            if (mounted) Navigator.pop(context, true);
          } else {
            setState(() {
              _enteredPin = '';
              _firstPin = null;
              _errorText = '两次输入不一致，请重新设置';
              _isProcessing = false;
            });
          }
        }
      } else {
        // verify 模式
        final ok = await _service.verifyPinFor(widget.entryId, _enteredPin);
        if (ok) {
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() {
            _enteredPin = '';
            _errorText = '密码错误';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _enteredPin = '';
        _errorText = '出错：$e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _useBiometrics() async {
    setState(() => _isProcessing = true);
    final ok = await _service.authenticateWithBiometrics();
    if (ok) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _isProcessing = false;
        _errorText = '生物识别失败';
      });
    }
  }

  // 忘记密码：清空该篇密码 + 标记 is_locked=0
  Future<void> _resetPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置密码'),
        content: const Text('重置后该篇日记将被解锁，可重新加锁。\n确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    await _service.resetPinFor(widget.entryId);
    if (!mounted) return;
    // 标记 is_locked=0（解锁）
    await context.read<JournalProvider>().toggleLock(widget.entryId, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已重置，该篇日记已解锁')),
      );
      Navigator.pop(context, false); // 视为未通过验证，关闭锁屏
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSetMode = widget._mode == LockMode.setPin;
    final subtitle = isSetMode
        ? (_firstPin == null ? '请设置 6 位数字密码' : '请再次输入确认')
        : '请输入密码';

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(widget.title ?? '隐私锁',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 20),
            _buildPinDots(theme),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(_errorText!,
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            _buildNumPad(theme),
            const SizedBox(height: 12),
            // 生物识别按钮（仅 verify 模式且硬件支持）
            if (_biometricsAvailable && !isSetMode)
              TextButton.icon(
                onPressed: _isProcessing ? null : _useBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text('使用生物识别'),
              ),
            // 忘记密码入口（仅 verify 模式）
            if (!isSetMode)
              TextButton(
                onPressed: _isProcessing ? null : _resetPin,
                child: const Text('忘记密码？', style: TextStyle(fontSize: 12)),
              ),
            // 取消
            TextButton(
              onPressed:
                  _isProcessing ? null : () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < _enteredPin.length;
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? theme.colorScheme.primary : Colors.transparent,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildNumPad(ThemeData theme) {
    // 1-9, 空, 0, 退格
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return Column(
      children: [
        for (int r = 0; r < 4; r++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (c) {
              final k = keys[r * 3 + c];
              if (k.isEmpty) return const SizedBox(width: 64, height: 56);
              if (k == '⌫') {
                return SizedBox(
                  width: 64,
                  height: 56,
                  child: IconButton(
                    onPressed: _backspace,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                );
              }
              return SizedBox(
                width: 64,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _appendDigit(k),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(k, style: const TextStyle(fontSize: 20)),
                ),
              );
            }),
          ),
      ],
    );
  }
}
