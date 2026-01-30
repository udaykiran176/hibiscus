// 浏览器入口组件
// 根据激活状态决定显示浏览器还是主应用

import 'package:flutter/material.dart';
import 'package:hibiscus/browser/browser_state.dart';
import 'package:hibiscus/browser/browser_page.dart';
import 'package:hibiscus/src/ui/theme/app_theme.dart';
import 'package:signals/signals_flutter.dart';

/// 应用入口组件
/// 首次启动时显示浏览器，用户输入 hibi://start 后切换到主应用
class BrowserEntry extends StatefulWidget {
  /// 主应用构建器
  final Widget Function() appBuilder;

  const BrowserEntry({
    super.key,
    required this.appBuilder,
  });

  @override
  State<BrowserEntry> createState() => _BrowserEntryState();
}

class _BrowserEntryState extends State<BrowserEntry> {
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    // 监听激活状态变化
    _activated = browserState.isActivated.value;
  }

  void _onActivated() {
    setState(() {
      _activated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果已激活，显示主应用
    if (_activated) {
      return widget.appBuilder();
    }

    // 否则显示浏览器
    return MaterialApp(
      title: 'Hibiscus Browser',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: BrowserPage(
        onActivated: _onActivated,
      ),
    );
  }
}

/// 浏览器欢迎页
/// 用于显示使用说明和激活入口
class BrowserWelcomePage extends StatelessWidget {
  final VoidCallback? onNavigate;

  const BrowserWelcomePage({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Logo 和标题
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.public,
                        size: 64,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Hibiscus Browser',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '内置浏览器',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 使用说明
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          '使用说明',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStep(
                      context,
                      '1',
                      '使用浏览器自由浏览网页',
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      context,
                      '2',
                      '在地址栏输入 hibi://start',
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      context,
                      '3',
                      '按回车即可进入主应用',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 开始浏览按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.explore),
                  label: const Text('开始浏览'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: onNavigate,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// 激活状态监听器
/// 用于在其他地方监听激活状态变化
class ActivationListener extends StatelessWidget {
  final Widget Function(BuildContext context, bool isActivated) builder;

  const ActivationListener({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isActivated = browserState.isActivated.value;
      return builder(context, isActivated);
    });
  }
}
