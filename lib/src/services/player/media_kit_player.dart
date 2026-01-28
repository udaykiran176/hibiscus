// MediaKit 播放器实现

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:hibiscus/src/services/player/player_service.dart';
import 'package:hibiscus/src/state/settings_state.dart';

class MediaKitPlayer implements PlayerService {
  late final Player _player;
  late final VideoController _controller;
  final _stateController = StreamController<PlayerState>.broadcast();
  PlayerState _currentState = const PlayerState();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<int?>? _widthSub;
  StreamSubscription<int?>? _heightSub;
  StreamSubscription<String>? _errorSub;

  Orientation _lastOrientation = Orientation.portrait;

  MediaKitPlayer() {
    _player = Player();
    _controller = VideoController(_player);
    _setupListeners();
  }

  void _setupListeners() {
    _positionSub = _player.stream.position.listen((position) {
      _updateState(_currentState.copyWith(position: position));
    });

    _durationSub = _player.stream.duration.listen((duration) {
      _updateState(_currentState.copyWith(duration: duration));
    });

    _playingSub = _player.stream.playing.listen((playing) {
      _updateState(_currentState.copyWith(isPlaying: playing));
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      _updateState(_currentState.copyWith(isBuffering: buffering));
    });

    _widthSub = _player.stream.width.listen((width) {
      _updateState(_currentState.copyWith(width: width));
    });

    _heightSub = _player.stream.height.listen((height) {
      _updateState(_currentState.copyWith(height: height));
    });

    _errorSub = _player.stream.error.listen((error) {
      if (error.isNotEmpty) {
        _updateState(_currentState.copyWith(error: error));
      }
    });
  }

  void _updateState(PlayerState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  PlayerType get playerType => PlayerType.mediaKit;

  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  @override
  PlayerState get currentState => _currentState;

  @override
  Future<void> openUrl(
    String url, {
    Map<String, String>? headers,
    bool autoPlay = true,
    Duration? startPosition,
  }) async {
    _updateState(const PlayerState(isBuffering: true));

    await _player.open(
      Media(url, httpHeaders: headers ?? {}),
      play: startPosition == null ? autoPlay : false,
    );

    if (startPosition != null) {
      await _seekWhenReady(startPosition);
      if (autoPlay) {
        await _player.play();
      }
    }
  }

  @override
  Future<void> openFile(
    String path, {
    bool autoPlay = true,
    Duration? startPosition,
  }) async {
    _updateState(const PlayerState(isBuffering: true));

    await _player.open(
      Media(path),
      play: startPosition == null ? autoPlay : false,
    );

    if (startPosition != null) {
      await _seekWhenReady(startPosition);
      if (autoPlay) {
        await _player.play();
      }
    }
  }

  Future<void> _seekWhenReady(Duration position) async {
    try {
      await _player.stream.duration
          .where((d) => d > Duration.zero)
          .first
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // ignore timeout
    }
    try {
      await _player.seek(position);
    } catch (_) {
      // ignore seek error
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0) * 100);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _widthSub?.cancel();
    await _heightSub?.cancel();
    await _errorSub?.cancel();
    await _stateController.close();
    await _player.dispose();
  }

  @override
  bool get supportsPictureInPicture => false;

  @override
  Future<void> enterPictureInPicture() async {
    // MediaKit 不支持画中画
  }

  @override
  Future<void> exitPictureInPicture() async {
    // MediaKit 不支持画中画
  }

  @override
  bool get isInPictureInPicture => false;

  @override
  Future<void> enterFullscreen() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return defaultEnterNativeFullscreen();
    }

    final mode = settingsState.settings.value.fullscreenOrientationMode;
    final isPortrait = _lastOrientation == Orientation.portrait;
    final w = _player.state.width ?? 0;
    final h = _player.state.height ?? 0;
    final isLandscapeVideo = w > 0 && h > 0 && w >= h;

    final orientations = switch (mode) {
      FullscreenOrientationMode.keepCurrent => isPortrait
          ? <DeviceOrientation>[DeviceOrientation.portraitUp]
          : <DeviceOrientation>[
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
      FullscreenOrientationMode.portrait => <DeviceOrientation>[
          DeviceOrientation.portraitUp,
        ],
      FullscreenOrientationMode.landscape => <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      FullscreenOrientationMode.byVideoSize => isLandscapeVideo
          ? <DeviceOrientation>[
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : <DeviceOrientation>[DeviceOrientation.portraitUp],
    };

    await Future.wait([
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: const [],
      ),
      SystemChrome.setPreferredOrientations(orientations),
    ]);
  }

  @override
  Future<void> exitFullscreen() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return defaultExitNativeFullscreen();
    }
    await Future.wait([
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
      SystemChrome.setPreferredOrientations(const []),
    ]);
  }

  /// 更新设备方向状态
  void updateOrientation(Orientation orientation) {
    _lastOrientation = orientation;
  }

  /// 获取内部播放器（用于高级功能）
  Player get internalPlayer => _player;

  /// 获取视频控制器（用于高级功能）
  VideoController get videoController => _controller;

  @override
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    Color backgroundColor = Colors.black,
  }) {
    return Container(
      color: backgroundColor,
      child: Video(
        controller: _controller,
        onEnterFullscreen: enterFullscreen,
        onExitFullscreen: exitFullscreen,
        pauseUponEnteringBackgroundMode: Platform.isIOS ? false : true,
        resumeUponEnteringForegroundMode: Platform.isIOS,
        fit: fit,
      ),
    );
  }
}
