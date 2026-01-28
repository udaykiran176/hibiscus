// 统一的视频播放器组件
// 包装 PlayerService，提供统一的播放器 UI

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hibiscus/src/services/player/player.dart';
import 'package:hibiscus/src/rust/api/user.dart' as user_api;

/// 视频播放器控制器回调
typedef PlayerReadyCallback = void Function(PlayerService player);

/// 视频播放器组件
class VideoPlayerWidget extends StatefulWidget {
  /// 视频 ID（用于历史记录）
  final String videoId;

  /// 视频标题（用于历史记录）
  final String title;

  /// 封面 URL
  final String? coverUrl;

  /// 视频 URL（网络视频）
  final String? videoUrl;

  /// 本地文件路径（本地视频）
  final String? localPath;

  /// HTTP 请求头（网络视频）
  final Map<String, String>? headers;

  /// 是否自动播放
  final bool autoPlay;

  /// 是否自动恢复进度
  final bool autoResumeProgress;

  /// 封面组件（不提供则使用默认样式）
  final Widget? coverWidget;

  /// 播放器准备好时的回调
  final PlayerReadyCallback? onPlayerReady;

  /// 播放状态变化回调
  final void Function(PlayerState state)? onStateChanged;

  /// 可选控制器（用于外部控制）
  final VideoPlayerController? controller;

  const VideoPlayerWidget({
    super.key,
    required this.videoId,
    required this.title,
    this.coverUrl,
    this.videoUrl,
    this.localPath,
    this.headers,
    this.autoPlay = true,
    this.autoResumeProgress = true,
    this.coverWidget,
    this.onPlayerReady,
    this.onStateChanged,
    this.controller,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final PlayerService _player;
  StreamSubscription<PlayerState>? _stateSub;
  bool _hasOpened = false;
  bool _isInitialized = false;

  // 历史记录相关
  Timer? _historyTimer;
  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;
  int _lastSavedAtMs = 0;

  @override
  void initState() {
    super.initState();
    _player = PlayerFactory.create();
    _setupListeners();
    widget.controller?._attach(this);

    // 自动播放
    if (widget.autoPlay && (widget.videoUrl != null || widget.localPath != null)) {
      _openAndPlay();
    }
  }

  void _setupListeners() {
    _stateSub = _player.stateStream.listen((state) {
      _lastPosition = state.position;
      _lastDuration = state.duration;
      widget.onStateChanged?.call(state);

      if (!_isInitialized && state.duration > Duration.zero) {
        _isInitialized = true;
        widget.onPlayerReady?.call(_player);
      }

      if (mounted) setState(() {});
    });

    // 定期保存播放进度
    _historyTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _flushHistory(),
    );
  }

  Future<void> _openAndPlay() async {
    Duration? resumeAt;
    if (widget.autoResumeProgress) {
      resumeAt = await _loadResumePosition();
    }

    if (widget.localPath != null) {
      await _player.openFile(
        widget.localPath!,
        autoPlay: true,
        startPosition: resumeAt,
      );
    } else if (widget.videoUrl != null) {
      await _player.openUrl(
        widget.videoUrl!,
        headers: widget.headers,
        autoPlay: true,
        startPosition: resumeAt,
      );
    }
    _hasOpened = true;
  }

  /// 加载恢复位置
  Future<Duration?> _loadResumePosition() async {
    try {
      final history = await user_api.getVideoProgress(videoId: widget.videoId);
      if (history == null) return null;
      final duration = history.duration;
      if (duration <= 0) return null;
      final seconds = (history.progress.clamp(0.0, 1.0) * duration).round();
      // 跳过开头 3 秒和结尾 3 秒
      if (seconds < 3) return null;
      if (seconds >= duration - 3) return null;
      return Duration(seconds: seconds);
    } catch (_) {
      return null;
    }
  }

  /// 保存播放进度
  Future<void> _flushHistory({bool force = false}) async {
    if (!_hasOpened) return;
    if (_lastDuration <= Duration.zero) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastSavedAtMs < 4000) return;

    final durMs = _lastDuration.inMilliseconds;
    if (durMs <= 0) return;
    final posMs = _lastPosition.inMilliseconds.clamp(0, durMs);
    final progress = (posMs / durMs).clamp(0.0, 1.0);
    if (!force && progress <= 0) return;

    _lastSavedAtMs = now;
    try {
      await user_api.updatePlayHistory(
        videoId: widget.videoId,
        title: widget.title,
        coverUrl: widget.coverUrl ?? '',
        progress: progress,
        duration: _lastDuration.inSeconds,
      );
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _flushHistory(force: true);
    _historyTimer?.cancel();
    _stateSub?.cancel();
    widget.controller?._detach();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 播放器
          _player.buildVideoWidget(),

          // 封面占位（未打开播放器时显示）
          if (!_hasOpened) _buildCoverOverlay(),
        ],
      ),
    );
  }

  Widget _buildCoverOverlay() {
    return GestureDetector(
      onTap: _openAndPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 封面
          if (widget.coverWidget != null)
            widget.coverWidget!
          else if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
            Image.network(
              widget.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // 播放按钮
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }

  /// 获取内部播放器服务（供外部调用高级功能）
  PlayerService get player => _player;

  /// 手动打开并播放视频（支持切换清晰度）
  Future<void> openUrl(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  }) async {
    // 保持当前进度（如果有）
    final currentPos = _lastPosition > Duration.zero ? _lastPosition : startPosition;
    await _player.openUrl(
      url,
      headers: headers ?? widget.headers,
      autoPlay: true,
      startPosition: currentPos,
    );
    _hasOpened = true;
    if (mounted) setState(() {});
  }

  /// 手动打开本地文件
  Future<void> openFile(
    String path, {
    Duration? startPosition,
  }) async {
    final currentPos = _lastPosition > Duration.zero ? _lastPosition : startPosition;
    await _player.openFile(
      path,
      autoPlay: true,
      startPosition: currentPos,
    );
    _hasOpened = true;
    if (mounted) setState(() {});
  }

  /// 是否已打开
  bool get hasOpened => _hasOpened;
}

/// 带控制器的视频播放器组件控制器
class VideoPlayerController {
  _VideoPlayerWidgetState? _state;

  void _attach(_VideoPlayerWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// 获取播放器服务
  PlayerService? get player => _state?._player;

  /// 打开视频 URL
  Future<void> openUrl(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  }) async {
    await _state?.openUrl(url, headers: headers, startPosition: startPosition);
  }

  /// 打开本地文件
  Future<void> openFile(String path, {Duration? startPosition}) async {
    await _state?.openFile(path, startPosition: startPosition);
  }

  /// 播放
  Future<void> play() async {
    await _state?._player.play();
  }

  /// 暂停
  Future<void> pause() async {
    await _state?._player.pause();
  }

  /// 跳转
  Future<void> seek(Duration position) async {
    await _state?._player.seek(position);
  }

  /// 是否支持画中画
  bool get supportsPictureInPicture =>
      _state?._player.supportsPictureInPicture ?? false;

  /// 进入画中画
  Future<void> enterPictureInPicture() async {
    await _state?._player.enterPictureInPicture();
  }

  /// 是否已打开
  bool get hasOpened => _state?._hasOpened ?? false;
}
