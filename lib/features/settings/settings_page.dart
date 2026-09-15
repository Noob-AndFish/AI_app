// 设置页面
// 主题切换（风格 + 模式）+ 预览卡片

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 主题风格切换 =====
          _SectionTitle(title: '主题风格'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThemeStyleCard(
                  label: '极简',
                  description: '黑白灰 · 小圆角',
                  isSelected: themeProvider.style == ThemeStyle.minimal,
                  preview: _MinimalPreview(),
                  onTap: () => themeProvider.setStyle(ThemeStyle.minimal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeStyleCard(
                  label: '治愈',
                  description: '奶油色 · 大圆角',
                  isSelected: themeProvider.style == ThemeStyle.healing,
                  preview: _HealingPreview(),
                  onTap: () => themeProvider.setStyle(ThemeStyle.healing),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ===== 主题模式切换 =====
          _SectionTitle(title: '主题模式'),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('浅色'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('跟随系统'),
                icon: Icon(Icons.settings_brightness),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('深色'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeProvider.mode},
            onSelectionChanged: (modes) =>
                themeProvider.setMode(modes.first),
          ),
          const SizedBox(height: 32),

          // ===== 其他设置占位 =====
          _SectionTitle(title: '其他'),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('应用锁'),
            subtitle: const Text('指纹/面容解锁'),
            trailing: Switch(
              value: false,
              onChanged: (v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('应用锁功能待开发')),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('数据备份与恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备份功能待开发')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于日迹'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '日迹',
                applicationVersion: '0.1.0',
                applicationLegalese: '个人离线效率工具',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===== 组件 =====

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// 主题风格预览卡片
class _ThemeStyleCard extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final Widget preview;
  final VoidCallback onTap;

  const _ThemeStyleCard({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 预览
              SizedBox(
                height: 80,
                child: preview,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 极简风格预览
class _MinimalPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MinimalColors.lightBackground,
        borderRadius: BorderRadius.circular(6), // 小圆角
      ),
      child: Column(
        children: [
          // 模拟 AppBar
          Container(
            height: 24,
            color: MinimalColors.lightBackground,
            alignment: Alignment.center,
            child: Text(
              '极简',
              style: TextStyle(
                color: MinimalColors.lightPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Divider(height: 1, color: MinimalColors.lightDivider),
          // 模拟卡片
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MinimalColors.lightSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: 60,
                    color: MinimalColors.lightDivider,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 治愈风格预览
class _HealingPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HealingColors.lightBackground,
        borderRadius: BorderRadius.circular(14), // 大圆角
        boxShadow: [
          BoxShadow(
            color: HealingColors.lightDivider.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: HealingColors.lightBackground,
            alignment: Alignment.center,
            child: Text(
              '治愈',
              style: TextStyle(
                color: HealingColors.lightPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: HealingColors.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: HealingColors.lightAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          width: 50,
                          decoration: BoxDecoration(
                            color: HealingColors.lightPrimary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
