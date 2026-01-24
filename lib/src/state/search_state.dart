// 搜索状态管理

import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/rust/api/search.dart' as search_api;
import 'package:hibiscus/src/rust/api/models.dart';

/// 搜索状态
class SearchState {
  // 单例
  static final SearchState _instance = SearchState._();
  factory SearchState() => _instance;
  SearchState._();

  // 过滤条件
  final filters = signal<ApiSearchFilters?>(null);

  // 可用的过滤选项（从网站获取）
  final filterOptions = signal<ApiFilterOptions?>(null);

  // 视频列表
  final videos = signal<List<ApiVideoCard>>([]);

  // 需要 Cloudflare 验证
  final needsCloudflare = signal(false);

  // 多选下载模式（发现页使用）
  final isMultiSelectMode = signal(false);
  final selectedVideoIds = signal<Set<String>>(<String>{});
  final multiSelectQuality = signal<String>('1080P');

  void enterMultiSelect({String? defaultQuality}) {
    isMultiSelectMode.value = true;
    selectedVideoIds.value = <String>{};
    if (defaultQuality != null && defaultQuality.isNotEmpty) {
      multiSelectQuality.value = defaultQuality;
    }
  }

  void exitMultiSelect() {
    isMultiSelectMode.value = false;
    selectedVideoIds.value = <String>{};
  }

  void toggleSelected(String videoId) {
    final next = <String>{...selectedVideoIds.value};
    if (next.contains(videoId)) {
      next.remove(videoId);
    } else {
      next.add(videoId);
    }
    selectedVideoIds.value = next;
  }

  void clearSelection() {
    selectedVideoIds.value = <String>{};
  }

  void selectAllVisible() {
    final next = <String>{...selectedVideoIds.value};
    for (final v in videos.value) {
      next.add(v.id);
    }
    selectedVideoIds.value = next;
  }

  /// 初始化默认过滤条件
  Future<void> init() async {
    if (filters.value != null) return;
    
    try {
      filters.value = await ApiSearchFilters.default_();
    } catch (e) {
      debugPrint('Failed to init filters: $e');
      // 使用本地默认值
      filters.value = const ApiSearchFilters(
        query: null,
        genre: null,
        tags: [],
        broadMatch: false,
        sort: null,
        year: null,
        month: null,
        date: null,
        duration: null,
        page: 1,
      );
    }
  }

  /// 加载过滤选项
  Future<void> loadFilterOptions() async {
    if (filterOptions.value != null) return;

    try {
      filterOptions.value = await search_api.getFilterOptions();
    } catch (e) {
      debugPrint('Failed to load filter options: $e');
    }
  }

  /// 执行搜索
  Future<ApiSearchResult> fetchPage({required int page}) async {
    await init();
    needsCloudflare.value = false;

    try {
      final current = filters.value!.copyWith(page: page);
      if (_shouldUseSearch(current)) {
        return await search_api.search(filters: current);
      }
      return await search_api.getHomeVideos(page: page);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('CLOUDFLARE_CHALLENGE')) {
        needsCloudflare.value = true;
      }
      rethrow;
    }
  }

  /// 更新过滤条件并重新搜索
  void updateFilters(ApiSearchFilters newFilters) {
    filters.value = newFilters;
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 更新搜索关键词
  void updateQuery(String query) {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(
      query: query.isEmpty ? null : query,
    );
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 更新类型
  void updateGenre(String? genre) {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(genre: genre);
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 更新标签
  void updateTags(List<String> tags) {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(tags: tags);
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 切换标签
  void toggleTag(String tag) {
    if (filters.value == null) return;
    final currentTags = List<String>.from(filters.value!.tags);
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }
    filters.value = filters.value!.copyWith(tags: currentTags);
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 更新排序
  void updateSort(String? sort) {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(sort: sort);
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 更新年份
  void updateYear(String? year) {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(year: year);
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 更新时长
  void updateDuration(String? duration) {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(duration: duration);
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 切换宽松匹配
  void toggleBroadMatch() {
    if (filters.value == null) return;
    filters.value = filters.value!.copyWith(
      broadMatch: !filters.value!.broadMatch,
    );
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 清除过滤条件（保留搜索词）
  void clearFilters() {
    if (filters.value == null) return;
    filters.value = ApiSearchFilters(
      query: filters.value!.query,
      genre: null,
      tags: const [],
      broadMatch: false,
      sort: null,
      year: null,
      month: null,
      date: null,
      duration: null,
      page: 1,
    );
    needsCloudflare.value = false;
    videos.value = [];
  }

  /// 完全重置
  void reset() {
    filters.value = const ApiSearchFilters(
      query: null,
      genre: null,
      tags: [],
      broadMatch: false,
      sort: null,
      year: null,
      month: null,
      date: null,
      duration: null,
      page: 1,
    );
    videos.value = [];
    needsCloudflare.value = false;
  }

  /// 是否有激活的过滤条件
  bool get hasActiveFilters {
    final f = filters.value;
    if (f == null) return false;
    return _shouldUseSearch(f);
  }

  /// 用于重置/复用列表状态的 key（包含全部搜索条件）
  String get filtersKey {
    final f = filters.value;
    if (f == null) return 'filters:null';
    final tags = [...f.tags]..sort();
    return [
      'q=${f.query ?? ''}',
      'genre=${f.genre ?? ''}',
      'tags=${tags.join(',')}',
      'broad=${f.broadMatch ? '1' : '0'}',
      'sort=${f.sort ?? ''}',
      'year=${f.year ?? ''}',
      'month=${f.month ?? ''}',
      'date=${f.date ?? ''}',
      'duration=${f.duration ?? ''}',
    ].join('|');
  }

  bool _shouldUseSearch(ApiSearchFilters? f) {
    if (f == null) return false;
    if (f.query != null && f.query!.isNotEmpty) return true;
    if (f.genre != null && f.genre!.isNotEmpty) return true;
    if (f.tags.isNotEmpty) return true;
    if (f.broadMatch) return true;
    if (f.sort != null && f.sort!.isNotEmpty) return true;
    if (f.year != null && f.year!.isNotEmpty) return true;
    if (f.month != null && f.month!.isNotEmpty) return true;
    if (f.date != null && f.date!.isNotEmpty) return true;
    if (f.duration != null && f.duration!.isNotEmpty) return true;
    return false;
  }
}

/// 全局搜索状态实例
final searchState = SearchState();
