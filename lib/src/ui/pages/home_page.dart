// 首页（搜索页）
// 参考官方布局，包含搜索框、过滤条件、视频列表

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/state/search_state.dart';
import 'package:hibiscus/src/state/settings_state.dart';
import 'package:hibiscus/src/ui/widgets/filter_bar.dart';
import 'package:hibiscus/src/ui/widgets/video_pager.dart';
import 'package:hibiscus/src/rust/api/download.dart' as download_api;
import 'package:hibiscus/src/ui/widgets/video_card.dart';

class HomePage extends StatefulWidget {
  /// 可选的独立搜索状态（用于发现页）
  final SearchState? searchState;
  
  /// 页面标题（用于发现页）
  final String? title;
  
  const HomePage({
    super.key,
    this.searchState,
    this.title,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  late final SearchState _searchState;

  @override
  bool get wantKeepAlive => widget.searchState == null; // 仅全局状态保持活动

  @override
  void initState() {
    super.initState();
    // 使用传入的状态或全局状态
    _searchState = widget.searchState ?? searchState;
    // 加载首页数据
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _searchState.init();
    await _searchState.loadFilterOptions();
    _searchController.text = _searchState.filters.value?.query ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    // 如果是独立实例，清理资源
    if (widget.searchState != null) {
      widget.searchState!.dispose();
    }
    super.dispose();
  }

  void _onSearch(String query) {
    _searchState.updateQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Watch((context) {
      final isMultiSelect = _searchState.isMultiSelectMode.value;
      final selectedCount = _searchState.selectedVideoIds.value.length;
      final pagerKey = _searchState.filtersKey;
      final needsCloudflare = _searchState.needsCloudflare.value;

      return Scaffold(
        appBar: AppBar(
          // 发现页显示返回按钮
          leading: widget.searchState != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          title: isMultiSelect
              ? Text('已选择 $selectedCount')
              : widget.title != null
                  ? Text(widget.title!)
                  : _buildSearchField(context),
          titleSpacing: widget.searchState != null ? null : 16,
        ),
        body: Column(
          children: [
            // 发现页顶部显示搜索框（如果有标题）
            if (widget.title != null && widget.searchState != null)
              _buildSearchField(context),
            
            // 过滤条件栏
            FilterBar(
              searchState: _searchState,
              onEnterMultiSelect: () {
                FocusScope.of(context).unfocus();
                _searchState.enterMultiSelect(
                  defaultQuality: settingsState.settings.value.defaultDownloadQuality,
                );
              },
              onBatchDownload: _batchDownloadSelected,
            ),

            // 视频列表
            Expanded(
              child: needsCloudflare
                  ? _buildCloudflarePrompt(context)
                  : VideoPager(
                      key: ValueKey(pagerKey),
                      pageLoader: (page) async {
                        final result = await _searchState.fetchPage(page: page);
                        return VideoPagerPage(
                          videos: result.videos,
                          hasNext: result.hasNext,
                        );
                      },
                      onItemsChanged: (items) => _searchState.videos.value = items,
                      selectionMode: isMultiSelect,
                      selectedIds: _searchState.selectedVideoIds.value,
                      onToggleSelect: (video) => _searchState.toggleSelected(video.id),
                      itemBuilder: (context, video, sizeScale, selected, onTap) {
                        return VideoCard(
                          video: video,
                          sizeScale: sizeScale,
                          selectionMode: isMultiSelect,
                          selected: selected,
                          onTap: onTap,
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    
    // 发现页使用 Container 包裹
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索视频...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchState.reset();
                  setState(() {});
                },
              )
            : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearch,
      onChanged: (value) => setState(() {}),
    );
    
    // 如果是发现页，添加背景容器
    if (widget.title != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surface,
        child: searchField,
      );
    }
    
    return searchField;
  }

  // VideoPager 已处理错误态与重试按钮

  Future<void> _batchDownloadSelected() async {
    final ids = _searchState.selectedVideoIds.value.toList();
    if (ids.isEmpty) return;

    final quality = _searchState.multiSelectQuality.value;
    final videosById = {for (final v in _searchState.videos.value) v.id: v};

    int done = 0;
    int ok = 0;
    bool canceled = false;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('加入下载'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('正在加入 ${ids.length} 个视频…'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  canceled = true;
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
            ],
          );
        },
      ),
    );

    for (final id in ids) {
      if (canceled) break;
      final v = videosById[id];
      if (v == null) {
        done++;
        continue;
      }
      try {
        await download_api.addDownload(
          videoId: v.id,
          title: v.title,
          coverUrl: v.coverUrl,
          quality: quality,
          description: null,
          tags: v.tags,
        );
        ok++;
      } catch (_) {
        // ignore per-item failure
      }
      done++;
      if (!mounted) break;
    }

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    final total = done;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入下载：$ok/$total')),
    );
    _searchState.exitMultiSelect();
  }

  Widget _buildCloudflarePrompt(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '需要验证',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '请完成 Cloudflare 安全验证后继续',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: 打开 WebView 进行验证
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('开始验证'),
            ),
          ],
        ),
      ),
    );
  }
}
