// 图片缓存服务
// 封装 Rust 层的图片缓存功能

import 'package:hibiscus/src/rust/api/cache.dart' as cache_api;

/// 缓存大小信息
class CacheSizeInfo {
  final int imageCacheBytes;
  final int imageCacheCount;
  final int webCacheCount;

  CacheSizeInfo({
    required this.imageCacheBytes,
    required this.imageCacheCount,
    required this.webCacheCount,
  });

  /// 格式化图片缓存大小
  String get formattedImageSize {
    if (imageCacheBytes < 1024) {
      return '$imageCacheBytes B';
    } else if (imageCacheBytes < 1024 * 1024) {
      return '${(imageCacheBytes / 1024).toStringAsFixed(1)} KB';
    } else if (imageCacheBytes < 1024 * 1024 * 1024) {
      return '${(imageCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(imageCacheBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 总条目数
  int get totalCount => imageCacheCount + webCacheCount;
}

/// 图片缓存服务
class ImageCacheService {
  ImageCacheService._();

  /// 获取缓存图片的本地路径
  /// 如果缓存不存在则下载
  static Future<String> getCachedImagePath(String url) async {
    return await cache_api.loadCachedImage(url: url);
  }

  /// 获取缓存大小信息
  static Future<CacheSizeInfo> getCacheSize() async {
    final size = await cache_api.getCacheSize();
    return CacheSizeInfo(
      imageCacheBytes: size.imageCacheBytes.toInt(),  // BigInt -> int
      imageCacheCount: size.imageCacheCount.toInt(),  // BigInt -> int
      webCacheCount: size.webCacheCount.toInt(),      // BigInt -> int
    );
  }

  /// 清理所有缓存
  static Future<void> clearAllCache() async {
    await cache_api.clearAllCache();
  }

  /// 仅清理图片缓存
  static Future<void> clearImageCache() async {
    await cache_api.clearImageCache();
  }

  /// 仅清理 Web 缓存
  static Future<void> clearWebCache() async {
    await cache_api.clearWebCache();
  }

  /// VACUUM 数据库
  static Future<void> vacuumDatabase() async {
    await cache_api.vacuumDatabase();
  }
}
