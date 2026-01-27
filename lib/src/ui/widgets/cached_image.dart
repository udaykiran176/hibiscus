// 缓存图片组件
// 使用 Rust 层的图片缓存，自动下载和缓存网络图片

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hibiscus/src/services/image_cache_service.dart';

/// 缓存网络图片组件
class CachedNetworkImage extends StatefulWidget {
  /// 图片 URL
  final String imageUrl;

  /// 图片填充方式
  final BoxFit? fit;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 加载中占位组件
  final Widget? placeholder;

  /// 错误时显示的组件
  final Widget? errorWidget;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 颜色混合
  final Color? color;

  /// 颜色混合模式
  final BlendMode? colorBlendMode;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
  });

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  String? _localPath;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = false;
      _localPath = null;
    });

    try {
      final path = await ImageCacheService.getCachedImagePath(widget.imageUrl);
      if (!mounted) return;
      
      // 验证文件存在
      if (await File(path).exists()) {
        setState(() {
          _localPath = path;
          _loading = false;
        });
      } else {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_loading) {
      child = widget.placeholder ?? _buildDefaultPlaceholder();
    } else if (_error || _localPath == null) {
      child = widget.errorWidget ?? _buildDefaultError();
    } else {
      child = Image.file(
        File(_localPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildDefaultError();
        },
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 缓存图片提供者（用于需要 ImageProvider 的场景）
class CachedNetworkImageProvider extends ImageProvider<CachedNetworkImageProvider> {
  final String url;

  const CachedNetworkImageProvider(this.url);

  @override
  Future<CachedNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
    CachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final path = await ImageCacheService.getCachedImagePath(key.url);
    final file = File(path);
    final bytes = await file.readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedNetworkImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedNetworkImageProvider($url)';
}
