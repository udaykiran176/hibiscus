// 播放器单例管理器
// 解决 BetterPlayer 内存泄漏问题

import 'package:flutter/widgets.dart';
import 'package:hibiscus/src/services/player/player_service.dart';
import 'package:hibiscus/src/services/player/player_factory.dart';

/// 播放器管理器（单例）
class PlayerManager with WidgetsBindingObserver {
  PlayerManager._() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  static final PlayerManager _instance = PlayerManager._();
  static PlayerManager get instance => _instance;

  PlayerService? _currentPlayer;
  int _usageCount = 0;

  /// 获取播放器实例（复用或创建）
  PlayerService acquire({PlayerType? type}) {
    // 如果已有播放器且类型匹配，复用
    if (_currentPlayer != null) {
      final currentType = _currentPlayer!.playerType;
      final desiredType = type ?? PlayerFactory.defaultType();
      
      if (currentType == desiredType) {
        _usageCount++;
        return _currentPlayer!;
      } else {
        // 类型不匹配，释放旧的
        _disposeCurrent();
      }
    }

    // 创建新播放器
    _currentPlayer = PlayerFactory.create(type: type);
    _usageCount = 1;
    return _currentPlayer!;
  }

  /// 释放播放器引用
  void release() {
    if (_currentPlayer == null) return;
    
    _usageCount--;
    if (_usageCount <= 0) {
      _usageCount = 0;
      // 延迟释放，给正在使用的页面一点时间
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_usageCount == 0) {
          _disposeCurrent();
        }
      });
    }
  }

  /// 强制释放当前播放器
  void _disposeCurrent() {
    _currentPlayer?.dispose();
    _currentPlayer = null;
    _usageCount = 0;
  }

  /// 强制清理（用于内存紧张时）
  void forceCleanup() {
    _disposeCurrent();
  }

  /// 检查是否有活动播放器
  bool get hasActivePlayer => _currentPlayer != null && _usageCount > 0;

  @override
  void didHaveMemoryPressure() {
    // 内存压力时，如果没有活动引用，立即清理播放器
    if (_usageCount == 0) {
      _disposeCurrent();
    }
  }

  /// 停止管理器（应用退出时调用）
  void shutdown() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrent();
  }
}
